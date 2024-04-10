defmodule ApplicationRunner.Session.UiBuilders.UiBuilderAdapter do
  @moduledoc """
  ApplicationRunner.UiBuilderAdapter provides the callback nedded to build a given UI.
  """

  alias ApplicationRunner.{Environment, JsonSchemata, Session, Ui}
  alias ApplicationRunner.Environment.ViewUid
  alias ApplicationRunner.Session
  alias ApplicationRunner.Session.RouteServer
  alias LenraCommon.Errors

  require Logger

  @type view :: map()
  @type component :: map()

  @type common_error :: Errors.BusinessError.t() | Errors.TechnicalError.t()

  @callback build_ui(Session.Metadata.t(), ViewUid.t()) ::
              {:ok, map()} | {:error, common_error()}

  @callback get_routes(number(), list(binary())) :: list(binary())

  @callback build_components(Session.Metadata.t(), map(), Ui.Context.t(), ViewUid.t()) ::
              {:ok, map(), Ui.Context.t()} | {:error, UiBuilderAdapter.common_error()}

  def build_ui(adapter, session_metadata, view_uid) do
    Logger.debug("#{__MODULE__} build_ui with session_metadata: #{inspect(session_metadata)}")

    with {:ok, ui_context} <- get_and_build_view(adapter, session_metadata, Ui.Context.new(), view_uid) do
      {:ok, transform(Map.fetch!(ui_context.views_map, view_id(view_uid)), ui_context.views_map)}
    end
  end

  defp transform(%{"_type" => "view", "id" => id}, views) do
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

  @spec get_and_build_view(UiBuilderAdapter, Session.Metadata.t(), Ui.Context.t(), ViewUid.t()) ::
          {:ok, Ui.Context.t()} | {:error, UiBuilderAdapter.common_error()}
  defp get_and_build_view(
         adapter,
         %Session.Metadata{} = session_metadata,
         %Ui.Context{} = ui_context,
         %ViewUid{} = view_uid
       ) do
    with {:ok, view} <- RouteServer.fetch_view(session_metadata, view_uid),
         {:ok, component, new_app_context} <-
           adapter.build_components(session_metadata, view, ui_context, view_uid) do
      str_view_id = view_id(view_uid)
      {:ok, put_in(new_app_context.views_map[str_view_id], component)}
    end
  end

  # Build a view means :
  # - getting the name and props, coll and query of the view
  # - create the ID of the view with name/data/props
  # - Create a new viewContext corresponding to the view
  # - Recursively get_and_build_view.
  @spec handle_view(UiBuilderAdapter, Session.Metadata.t(), view(), Ui.Context.t(), ViewUid.t()) ::
          {:ok, component(), Ui.Context.t()} | {:error, UiBuilderAdapter.common_error()}
  def handle_view(adapter, session_metadata, component, ui_context, view_uid) do
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
             session_metadata.context,
             context_projection,
             view_uid.prefix_path
           ),
         {:ok, new_app_context} <-
           get_and_build_view(adapter, session_metadata, ui_context, new_view_uid) do
      {
        :ok,
        %{"_type" => "view", "id" => view_id(new_view_uid), "name" => name},
        new_app_context
      }
    end
  end

  # Build a view means :
  # - getting the name and props, coll and query of the view
  # - create the ID of the view with name/data/props
  # - Create a new viewContext corresponding to the view
  # - Recursively get_and_build_view.
  @spec handle_listener(UiBuilderAdapter, Session.Metadata.t(), view(), Ui.Context.t(), ViewUid.t()) ::
          {:ok, component(), Ui.Context.t()} | {:error, UiBuilderAdapter.common_error()}
  def handle_listener(_adapter, session_metadata, component, ui_context, _view_uid) do
    with {:ok, listener} <-
           RouteServer.build_listener(session_metadata, component) do
      {
        :ok,
        listener,
        ui_context
      }
    end
  end

  defp view_id(%ViewUid{} = view_uid) do
    Crypto.hash({view_uid.name, view_uid.coll, view_uid.query_parsed, view_uid.props})
  end
end
