defmodule ApplicationRunner.Session.UiBuilders.LenraBuilder do
  @moduledoc """
      This module is responsible of building the Lenra view.
  """
  @behaviour ApplicationRunner.Session.UiBuilders.UiBuilderAdapter

  alias ApplicationRunner.{Environment, JsonSchemata, Session, Ui}
  alias ApplicationRunner.Environment.ViewUid
  alias ApplicationRunner.Session.RouteServer
  alias ApplicationRunner.Session.UiBuilders.UiBuilderAdapter
  alias LenraCommon.Errors

  require Logger

  @type view :: map()
  @type component :: map()

  def get_routes(env_id, roles) do
    Environment.ManifestHandler.get_routes(env_id, "lenra", roles)
  end

  def build_ui(session_metadata, view_uid) do
    Logger.debug("#{__MODULE__} build_ui with session_metadata: #{inspect(session_metadata)}")

    with {:ok, ui_context} <- get_and_build_view(session_metadata, Ui.Context.new(), view_uid) do
      {:ok,
       transform_ui(%{
         "rootView" => view_id(view_uid),
         "views" => ui_context.views_map
       })}
    end
  end

  defp transform_ui(%{"rootView" => root_views, "views" => views}) do
    transform(%{"root" => Map.fetch!(views, root_views)}, views)
  end

  defp transform(%{"type" => "view", "id" => id}, views) do
    transform(Map.fetch!(views, id), views)
  end

  defp transform(view, views) when is_map(view) do
    Enum.map(view, fn
      {k, v} -> {k, transform(v, views)}
    end)
    |> Map.new()
  end

  defp transform(view, views) when is_list(view) do
    Enum.map(view, &transform(&1, views))
  end

  defp transform(view, _views) do
    view
  end

  @spec get_and_build_view(Session.Metadata.t(), Ui.Context.t(), ViewUid.t()) ::
          {:ok, Ui.Context.t()} | {:error, UiBuilderAdapter.common_error()}
  defp get_and_build_view(
         %Session.Metadata{} = session_metadata,
         %Ui.Context{} = ui_context,
         %ViewUid{} = view_uid
       ) do
    with {:ok, view} <- RouteServer.fetch_view(session_metadata, view_uid),
         {:ok, component, new_app_context} <-
           build_component(session_metadata, view, ui_context, view_uid) do
      str_view_id = view_id(view_uid)
      {:ok, put_in(new_app_context.views_map[str_view_id], component)}
    end
  end

  # Build a component.
  # If the component type is "view" this is considered a view and will be handled like one.
  # Everything else will be handled as a simple component.
  @spec build_component(Session.Metadata.t(), view(), Ui.Context.t(), ViewUid.t()) ::
          {:ok, component(), Ui.Context.t()} | {:error, UiBuilderAdapter.common_error()}
  defp build_component(
         session_metadata,
         %{"_type" => comp_type} = component,
         ui_context,
         view_uid
       ) do
    Logger.debug("#{__MODULE__} build_component with component: #{inspect(component)}")

    with schema_path <- JsonSchemata.get_component_path(comp_type),
         {:ok, validation_data} <- validate_with_error(schema_path, component, view_uid) do
      case comp_type do
        "view" ->
          handle_view(session_metadata, component, ui_context, view_uid)

        _ ->
          handle_component(
            session_metadata,
            component,
            ui_context,
            view_uid,
            validation_data
          )
      end
    end
  end

  defp build_component(
         _session_metadata,
         component,
         _ui_context,
         view_uid
       ) do
    ApplicationRunner.Errors.BusinessError.components_malformated_tuple(%{
      view: view_uid.name,
      at: view_uid.prefix_path,
      receive: component
    })
  end

  # Build a view means :
  # - getting the name and props, coll and query of the view
  # - create the ID of the view with name/data/props
  # - Create a new viewContext corresponding to the view
  # - Recursively get_and_build_view.
  @spec handle_view(Session.Metadata.t(), view(), Ui.Context.t(), ViewUid.t()) ::
          {:ok, component(), Ui.Context.t()} | {:error, UiBuilderAdapter.common_error()}
  defp handle_view(session_metadata, component, ui_context, view_uid) do
    name = Map.get(component, "name")
    props = Map.get(component, "props")
    find = Map.get(component, "find", %{})
    context_projection = Map.get(component, "context")

    {coll, query, projection} = RouteServer.extract_find(component, find)

    with {:ok, new_view_uid} <-
           RouteServer.create_view_uid(
             session_metadata,
             name,
             %{coll: coll, query: query, projection: projection},
             %{},
             props,
             view_uid.context,
             context_projection,
             view_uid.prefix_path
           ),
         {:ok, new_app_context} <-
           get_and_build_view(session_metadata, ui_context, new_view_uid) do
      {
        :ok,
        %{"type" => "view", "id" => view_id(new_view_uid), "name" => name},
        new_app_context
      }
    end
  end

  # Build a components means to :
  #   - Recursively build all children (list of child) properties
  #   - Recursively build all single child properties
  #   - Build all listeners
  #   - Then merge all children/child context/view with the current one.
  @spec handle_component(
          Session.Metadata.t(),
          component(),
          Ui.Context.t(),
          ViewUid.t(),
          map()
        ) ::
          {:ok, component(), Ui.Context.t()} | {:error, UiBuilderAdapter.common_error()}
  defp handle_component(
         %Session.Metadata{} = session_metadata,
         component,
         ui_context,
         view_uid,
         %{listeners: listeners_keys, children: children_keys, child: child_keys}
       ) do
    with {:ok, children_map, merged_children_ui_context} <-
           build_children_list(
             session_metadata,
             component,
             children_keys,
             ui_context,
             view_uid
           ),
         {:ok, child_map, merged_child_ui_context} <-
           build_child_list(session_metadata, component, child_keys, ui_context, view_uid),
         {:ok, listeners_map} <-
           build_listeners(session_metadata, component, listeners_keys) do
      new_context = %Ui.Context{
        views_map:
          Map.merge(merged_child_ui_context.views_map, merged_children_ui_context.views_map),
        listeners_map:
          Map.merge(
            merged_child_ui_context.listeners_map,
            merged_children_ui_context.listeners_map
          )
      }

      {:ok,
       component
       |> Map.merge(children_map)
       |> Map.merge(child_map)
       |> Map.merge(listeners_map), new_context}
    end
  end

  # Validate the component against the corresponding Json Schema.
  # Returns the data needed for the component to build.
  # If there is a validation error, return the `{:error, build_errors}` tuple.
  @spec validate_with_error(String.t(), component(), ViewUid.t()) ::
          {:error, UiBuilderAdapter.common_error()} | {:ok, map()}
  defp validate_with_error(schema_path, component, %ViewUid{prefix_path: prefix_path}) do
    with %{schema: schema} = schema_map <-
           JsonSchemata.get_schema_map(schema_path),
         :ok <-
           ExComponentSchema.Validator.validate(schema, component) do
      {:ok, schema_map}
    else
      {:error, errors} ->
        err_message =
          Enum.reduce(errors, "", fn
            {message, "#" <> path}, acc ->
              acc <> "#{message}#{prefix_path <> path}\n\n"
          end)

        {:error, %Errors.BusinessError{message: err_message, reason: :build_errors}}
    end
  end

  # Build all child properties of the `component` from the given `child_list` of child properties.
  # Return {:ok, builded_component, updated_ui_context} in case of success.
  # Return {:error, build_errors} in case of any failure in one child.
  @spec build_child_list(
          Session.Metadata.t(),
          component(),
          list(String.t()),
          Ui.Context.t(),
          ViewUid.t()
        ) ::
          {:ok, map(), Ui.Context.t()} | {:error, UiBuilderAdapter.common_error()}
  defp build_child_list(
         session_metadata,
         component,
         child_list,
         ui_context,
         view_uid
       ) do
    case reduce_child_list(session_metadata, component, child_list, ui_context, view_uid) do
      {:error, error} -> {:error, error}
      {comp, merged_ui_context} -> {:ok, comp, merged_ui_context}
    end
  end

  defp reduce_child_list(
         session_metadata,
         component,
         child_list,
         ui_context,
         %ViewUid{prefix_path: prefix_path} = view_uid
       ) do
    Enum.reduce_while(
      child_list,
      {%{}, ui_context},
      fn child_key, {child_map, ui_context_acc} ->
        case Map.get(component, child_key) do
          nil ->
            {:cont, {child_map, ui_context_acc}}

          child_comp ->
            com_type = Map.get(component, "_type")
            child_path = "#{prefix_path}/#{com_type}##{child_key}"

            build_comp_and_format(
              session_metadata,
              child_map,
              child_comp,
              child_key,
              ui_context_acc,
              ui_context,
              Map.put(view_uid, :prefix_path, child_path)
            )
        end
      end
    )
  end

  defp build_comp_and_format(
         session_metadata,
         child_map,
         child_comp,
         child_key,
         ui_context_acc,
         ui_context,
         view_uid
       ) do
    case build_component(
           session_metadata,
           child_comp,
           ui_context,
           view_uid
         ) do
      {:ok, built_component, child_ui_context} ->
        {
          :cont,
          {
            Map.merge(child_map, %{child_key => built_component}),
            merge_ui_context(ui_context_acc, child_ui_context)
          }
        }

      {:error, comp_error} ->
        {:halt, {:error, comp_error}}
    end
  end

  # Build all children properties of the `component` from the given `children_list` of children properties.
  # Return {:ok, builded_component, updated_ui_context} in case of success.
  # Return {:error, build_errors} in case of any failure in one children list.
  @spec build_children_list(
          Session.Metadata.t(),
          component(),
          list(),
          Ui.Context.t(),
          ViewUid.t()
        ) ::
          {:ok, map(), Ui.Context.t()} | {:error, UiBuilderAdapter.common_error()}
  defp build_children_list(
         session_metadata,
         component,
         children_keys,
         %Ui.Context{} = ui_context,
         %ViewUid{prefix_path: prefix_path} = view_uid
       ) do
    Logger.debug(
      "#{__MODULE__} build_children_list with component: #{inspect(component)}, children_key: #{children_keys}"
    )

    Enum.reduce_while(
      children_keys,
      {%{}, ui_context},
      fn children_key, {children_map, app_context_acc} = acc ->
        if Map.has_key?(component, children_key) do
          comp_type = Map.get(component, "_type")
          children_path = "#{prefix_path}/#{comp_type}##{children_key}"

          case build_children(
                 session_metadata,
                 component,
                 children_key,
                 ui_context,
                 Map.put(view_uid, :prefix_path, children_path)
               ) do
            {:ok, built_children, children_ui_context} ->
              {
                :cont,
                {
                  Map.merge(children_map, %{children_key => built_children}),
                  merge_ui_context(app_context_acc, children_ui_context)
                }
              }

            {:error, child_error} ->
              {:halt, {:error, child_error}}
          end
        else
          {:cont, acc}
        end
      end
    )
    |> case do
      {:error, child_error} -> {:error, child_error}
      {children_map, merged_app_context} -> {:ok, children_map, merged_app_context}
    end
  end

  @spec build_children(Session.Metadata.t(), map, String.t(), Ui.Context.t(), ViewUid.t()) ::
          {:error, UiBuilderAdapter.common_error()} | {:ok, list(component()), Ui.Context.t()}
  defp build_children(session_metadata, component, children_key, ui_context, view_uid) do
    Logger.debug(
      "#{__MODULE__} build_children with component: #{inspect(component)}, children_key: #{children_key}"
    )

    case Map.get(component, children_key) do
      nil ->
        {:ok, [], ui_context}

      children ->
        try do
          build_children_map(session_metadata, children, ui_context, view_uid)
        rescue
          e ->
            Logger.error(
              "#{__MODULE__} failed to build children map for session_metadata: #{inspect(session_metadata)} with children: #{inspect(children)} and error: #{inspect(e)}"
            )
        end
    end
  end

  defp build_children_map(
         session_metadata,
         children,
         ui_context,
         %ViewUid{prefix_path: prefix_path} = view_uid
       ) do
    Logger.debug("#{__MODULE__} build_children_map with children: #{inspect(children)}")

    children
    |> Enum.with_index()
    |> Parallel.map(fn {child, index} ->
      children_path = "#{prefix_path}/#{index}"

      build_component(
        session_metadata,
        child,
        ui_context,
        Map.put(view_uid, :prefix_path, children_path)
      )
    end)
    |> Enum.reduce_while(
      {[], ui_context},
      fn builded_child, {built_components, ui_context_acc} ->
        case builded_child do
          {:ok, built_component, new_ui_context} ->
            {:cont,
             {built_components ++ [built_component],
              merge_ui_context(ui_context_acc, new_ui_context)}}

          {:error, child_error} ->
            {:halt, {:error, child_error}}
        end
      end
    )
    |> case do
      {:error, error} -> {:error, error}
      {comp, merged_app_context} -> {:ok, comp, merged_app_context}
    end
  end

  defp merge_ui_context(ui_context1, ui_context2) do
    Map.put(
      ui_context1,
      :views_map,
      Map.merge(ui_context1.views_map, ui_context2.views_map)
    )
  end

  @spec build_listeners(Session.Metadata.t(), component(), list(String.t())) ::
          {:ok, map()} | {:error, UiBuilderAdapter.common_error()}
  defp build_listeners(session_metadata, component, listeners_keys) do
    Logger.debug(
      "#{__MODULE__} build_children_map with children: #{inspect(component)}, listeners_keys: #{inspect(listeners_keys)}"
    )

    Enum.reduce_while(
      listeners_keys,
      {:ok, %{}},
      fn listener_key, {:ok, built_listeners} = acc ->
        with {:fetch, {:ok, listener}} <- {:fetch, Map.fetch(component, listener_key)},
             {:build, {:ok, built_listener}} <-
               {:build, RouteServer.build_listener(session_metadata, listener)} do
          {:cont, {:ok, Map.put(built_listeners, listener_key, built_listener)}}
        else
          {:build, err} ->
            {:halt, err}

          {:fetch, :error} ->
            {:cont, acc}
        end
      end
    )
  end

  defp view_id(%ViewUid{} = view_uid) do
    Crypto.hash({view_uid.name, view_uid.coll, view_uid.query_parsed, view_uid.props})
  end
end
