defmodule ApplicationRunner.Session.RouteServer do
  @moduledoc """
    This module is started once per session and is responsible for the UI Rebuild.
    When a ChangeEventManager did notify all the QueryServer
    AND all the QueryServer did notify all the ViewServer,
    THEN the ChangeEventManager notify the RouteServer.

    The RouteServer then rebuild the entire UI using the ViewServer, store the new UI
    and create a diff between the old and the new UI to send it to the AppChannel.
  """
  use GenServer
  use SwarmNamed

  alias ApplicationRunner.MongoStorage.MongoUserLink
  alias ApplicationRunner.Environment.{ViewDynSup, ViewServer, ViewUid}
  alias ApplicationRunner.Errors.BusinessError
  alias ApplicationRunner.{MongoStorage, RouteChannel, Session}
  alias ApplicationRunner.Session.UiBuilders.UiBuilderAdapter
  alias ApplicationRunner.Utils
  alias LenraCommon.Errors
  alias QueryParser.Parser

  require Logger

  def start_link(opts) do
    Logger.notice("Start #{__MODULE__}")
    Logger.debug("#{__MODULE__} start_link with opts #{inspect(opts)}")

    session_id = Keyword.fetch!(opts, :session_id)
    mode = Keyword.fetch!(opts, :mode)
    route = Keyword.fetch!(opts, :route)
    GenServer.start_link(__MODULE__, opts, name: get_full_name({session_id, mode, route}))
  end

  def init(opts) do
    session_id = Keyword.fetch!(opts, :session_id)
    route = Keyword.fetch!(opts, :route)
    mode = Keyword.fetch!(opts, :mode)

    case load_ui(session_id, mode, route) do
      {:ok, ui} ->
        send_to_channel(session_id, mode, route, :ui, ui)
        {:ok, %{session_id: session_id, ui: ui, mode: mode, route: route}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_cast(
        :resync,
        %{session_id: session_id, ui: ui, route: route, mode: mode} = state
      ) do
    send_to_channel(session_id, mode, route, :ui, ui)

    {:noreply, state}
  end

  def handle_cast(
        :rebuild,
        %{session_id: session_id, ui: old_ui, route: route, mode: mode} = state
      ) do
    Logger.debug("#{__MODULE__} rebuild for state #{inspect(state)}")

    case load_ui(session_id, mode, route) do
      {:ok, ui} ->
        case JSONDiff.diff(old_ui, ui) do
          [] ->
            :ok

          patches ->
            send_to_channel(session_id, mode, route, :patches, patches)
        end

        {:noreply, Map.put(state, :ui, ui)}

      err ->
        send_to_channel(session_id, mode, route, :error, err)
        {:noreply, state}
    end
  end

  defp send_to_channel(session_id, mode, route, atom, stuff) do
    group_name = RouteChannel.get_group(session_id, mode, route)
    Swarm.publish(group_name, {:send, atom, stuff})
  end

  def load_ui(session_id, mode, route) do
    session_metadata = Session.MetadataAgent.get_metadata(session_id)
    builder_mod = get_builder_mode(mode)
    routes = builder_mod.get_routes(session_metadata.env_id)

    Logger.debug("#{__MODULE__} load_ui for state session_id:#{session_id}")

    with {:ok, route_params, base_view} <- find_route(routes, route),
         name <- Map.get(base_view, "name"),
         props <- Map.get(base_view, "props", %{}),
         find <- Map.get(base_view, "find", %{}),
         context_projection <- Map.get(base_view, "context"),
         {coll, query, projection} <- extract_find(base_view, find),
         {:ok, view_uid} <-
           create_view_uid(
             session_metadata,
             name,
             %{coll: coll, query: query, projection: projection},
             %{"route" => route_params},
             props,
             session_metadata.context,
             context_projection,
             ""
           ) do
      builder_mod.build_ui(session_metadata, view_uid)
    else
      :error ->
        BusinessError.route_does_not_exist_tuple(route)

      err ->
        err
    end
  end

  def extract_find(base_view, find) do
    coll_deprecated = Map.get(base_view, "coll")
    query_deprecated = Map.get(base_view, "query", %{})
    name = Map.get(base_view, "name")

    coll = Map.get(find, "coll")
    query = Map.get(find, "query", %{})
    projection = Map.get(find, "projection", %{})

    if find == %{} && coll_deprecated != nil do
      Logger.warning(
        "Definition of view #{name} is deprecated since applicationRunner beta 106 check https://docs.lenra.io/components-api/components/view.html."
      )

      {coll_deprecated, query_deprecated, %{}}
    else
      {coll, query, projection}
    end
  end

  defp find_route(routes, url) do
    Enum.reduce_while(
      routes,
      :error,
      fn route, _err ->
        path = Map.get(route, "path")
        view = Map.get(route, "view")

        case Utils.Routes.match_route(path, url) do
          {:error, err} ->
            {:cont, {:error, err}}

          {:ok, route_params} ->
            {:halt, {:ok, route_params, view}}
        end
      end
    )
  end

  defp get_builder_mode("lenra") do
    Session.UiBuilders.LenraBuilder
  end

  defp get_builder_mode("json") do
    Session.UiBuilders.JsonBuilder
  end

  defp get_builder_mode(mode) do
    raise Errors.DevError.exception(
            "The view mode '#{mode}' is incorrect. No UI Builder module can be found."
          )
  end

  @spec create_view_uid(
          Session.Metadata.t(),
          binary(),
          map(),
          map(),
          map() | nil,
          map(),
          map() | nil,
          binary()
        ) :: {:ok, ViewUid.t()} | {:error, LenraCommon.Errors.BusinessError.t()}
  def create_view_uid(
        session_metadata,
        name,
        find,
        query_params,
        props,
        context,
        context_projection,
        prefix_path
      ) do
    coll = Map.get(find, :coll)
    query = Map.get(find, :query)
    projection = Map.get(find, :projection)

    %MongoUserLink{mongo_user_id: mongo_user_id} =
      MongoStorage.get_mongo_user_link!(session_metadata.env_id, session_metadata.user_id)

    params = query_params |> Map.merge(%{"me" => mongo_user_id})
    query_transformed = Parser.replace_params(query, params)

    context =
      context
      |> Map.merge(%{"me" => mongo_user_id, "pathParams" => query_params["route"]})
      |> project_map(context_projection)

    with {:ok, query_parsed} <- parse_query(query, params) do
      {:ok,
       %ViewUid{
         name: name,
         props: props,
         prefix_path: "#{prefix_path}\n@view:#{name}",
         query_parsed: query_parsed,
         query_transformed: query_transformed,
         coll: coll,
         context: context,
         projection: projection
       }}
    end
  end

  @doc """
  Projects elements from the given map based on the provided projection.

  ## Examples

      iex> Projection.project_map(%{"foo" => "bar", "john" => "doe"}, %{"foo" => true})
      %{"foo" => "bar"}

  """
  @spec project_map(map(), map() | nil) :: map()
  def project_map(map, projection) do
    case projection do
      nil ->
        %{}

      _ ->
        Enum.reduce(projection, %{}, fn {key, true}, acc ->
          Map.put(acc, key, Map.get(map, key))
        end)
    end
  end

  @spec fetch_view(Session.Metadata.t(), ViewUid.t()) ::
          {:ok, map()} | {:error, UiBuilderAdapter.common_error()}
  def fetch_view(%Session.Metadata{} = session_metadata, %ViewUid{} = view_uid) do
    filtered_view_uid = Map.filter(view_uid, fn {key, _value} -> key != :prefix_path end)

    case ViewDynSup.ensure_child_started(
           session_metadata.env_id,
           session_metadata.session_id,
           session_metadata.function_name,
           filtered_view_uid
         ) do
      {:ok, _} ->
        view = ViewServer.fetch_view!(session_metadata.env_id, view_uid)
        {:ok, view}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec build_listener(Session.Metadata.t(), map()) ::
          {:ok, map()} | {:error, Errors.BusinessError.t()}
  def build_listener(session_metadata, listener) do
    case listener do
      %{"action" => action} ->
        props = Map.get(listener, "props", %{})
        code = Session.ListenersCache.create_code(action, props)
        Session.ListenersCache.save_listener(session_metadata.session_id, code, listener)
        {:ok, listener |> Map.drop(["action", "props", "type"]) |> Map.put("code", code)}

      %{"navTo" => nav_to} ->
        {:ok, %{"navTo" => nav_to}}

      _ ->
        BusinessError.no_action_in_listener_tuple(listener)
    end
  end

  defp parse_query(query, params) when not is_nil(query) do
    Parser.parse(Jason.encode!(query), params)
  end

  defp parse_query(nil, _params) do
    {:ok, nil}
  end
end
