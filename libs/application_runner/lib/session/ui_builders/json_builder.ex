defmodule ApplicationRunner.Session.UiBuilders.JsonBuilder do
  @moduledoc """
    This module is responsible of building the JSON view.
  """
  @behaviour ApplicationRunner.Session.UiBuilders.UiBuilderAdapter

  alias ApplicationRunner.Environment
  alias ApplicationRunner.Session.RouteServer

  require Logger

  @type view :: map()
  @type component :: map()

  @impl ApplicationRunner.Session.UiBuilders.UiBuilderAdapter
  def get_routes(env_id) do
    Environment.ManifestHandler.get_json_routes(env_id)
  end

  @impl ApplicationRunner.Session.UiBuilders.UiBuilderAdapter
  def build_ui(session_metadata, view_uid) do
    Logger.debug("#{__MODULE__} build_ui with session_metadata: #{inspect(session_metadata)}")

    with {:ok, json} <- RouteServer.fetch_view(session_metadata, view_uid) do
      build_listeners(session_metadata, json)
    end
  end

  def build_listeners(session_metadata, view) do
    {:ok, do_build_listeners(session_metadata, view)}
  rescue
    err -> {:error, err}
  end

  defp do_build_listeners(session_metadata, list) when is_list(list) do
    Enum.map(list, &do_build_listeners(session_metadata, &1))
  end

  defp do_build_listeners(session_metadata, %{"type" => "listener"} = listener) do
    case RouteServer.build_listener(session_metadata, listener) do
      {:ok, built_listener} ->
        built_listener

      err ->
        raise err
    end
  end

  defp do_build_listeners(session_metadata, map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {k, do_build_listeners(session_metadata, v)} end)
    |> Map.new()
  end

  defp do_build_listeners(_session_metadata, e) do
    e
  end
end
