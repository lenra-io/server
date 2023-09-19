defmodule ApplicationRunner.Environment.ManifestHandler do
  @moduledoc """
    Environment.ManifestHandler is a genserver that gets and caches the manifest of an app
  """
  use GenServer
  use SwarmNamed

  alias ApplicationRunner.ApplicationServices

  require Logger

  def start_link(opts) do
    Logger.debug("#{__MODULE__} start_link with #{inspect(opts)}")
    Logger.info("Start #{__MODULE__}")
    env_id = Keyword.fetch!(opts, :env_id)
    GenServer.start_link(__MODULE__, opts, name: get_full_name(env_id))
  end

  @impl true
  def init(opts) do
    Logger.debug("#{__MODULE__} init with #{inspect(opts)}")

    function_name = Keyword.fetch!(opts, :function_name)

    case ApplicationServices.fetch_manifest(function_name) do
      {:ok, manifest} ->
        {:ok, %{manifest: manifest}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  @doc """
   Returns the Manifest for the given env_id
  """
  @spec get_manifest(number()) :: map()
  def get_manifest(env_id) do
    GenServer.call(get_full_name(env_id), :get_manifest)
  end

  @spec get_lenra_routes(number()) :: map()
  def get_lenra_routes(env_id) do
    GenServer.call(get_full_name(env_id), :get_lenra_routes)
  end

  @spec get_json_routes(number()) :: map()
  def get_json_routes(env_id) do
    GenServer.call(get_full_name(env_id), :get_json_routes)
  end

  @impl true
  def handle_call(:get_manifest, _from, state) do
    Logger.debug("#{__MODULE__} handle call for :get_manifest with #{inspect(state)}")

    {:reply, Map.get(state, :manifest), state}
  end

  @default_routes [%{"path" => "/", "view" => %{"_type" => "view", "name" => "main"}}]

  def handle_call(:get_lenra_routes, _from, state) do
    Logger.debug("#{__MODULE__} handle call for :get_lenra_routes with #{inspect(state)}")

    manifest = Map.get(state, :manifest)

    {:reply, get_exposer_routes(manifest, "lenra"), state}
  end

  def handle_call(:get_json_routes, _from, state) do
    Logger.debug("#{__MODULE__} handle call for :get_json_routes with #{inspect(state)}")

    manifest = Map.get(state, :manifest)

    {:reply, get_exposer_routes(manifest, "json"), state}
  end

  defp get_exposer_routes(manifest, exposer) do
    manifest
    |> Map.get(exposer, %{"routes" => @default_routes})
    |> Map.get("routes", @default_routes)
  end
end
