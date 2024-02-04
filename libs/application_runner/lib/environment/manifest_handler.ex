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

  @spec get_routes(number(), String.t()) :: {:ok, list(binary())}
  defp get_routes(env_id, exposer) when exposer in ["lenra", "json"] do
    {:ok, GenServer.call(get_full_name(env_id), {:get_routes, exposer})}
  end

  defp get_routes(env_id, exposer) do
    {:error, "Exposer #{exposer} not supported"}
  end

  @spec get_routes(number(), String.t(), list(binary())) :: map()
  def get_routes(env_id, exposer, roles) do
    case get_routes(env_id, exposer) do
      {:ok, routes} ->
        filter_routes(routes, roles)

      {:error, reason} ->
        Logger.error("Could not get routes for env_id #{env_id} and exposer #{exposer} with reason #{inspect(reason)}")

        []
    end
  end

  defp filter_routes(routes, roles) do
    Enum.filter(routes, fn route ->
      Map.get(route, "roles", ["user"])
      |> Enum.any?(&Enum.member?(roles, &1))
    end)
  end

  @impl true
  def handle_call(:get_manifest, _from, state) do
    Logger.debug("#{__MODULE__} handle call for :get_manifest with #{inspect(state)}")

    {:reply, Map.get(state, :manifest), state}
  end

  def handle_call({:get_routes, exposer}, _from, state) do
    Logger.debug("#{__MODULE__} handle call for :get_routes for #{exposer} with #{inspect(state)}")

    manifest = Map.get(state, :manifest)

    {:reply, get_exposer_routes(manifest, exposer), state}
  end

  defp get_exposer_routes(manifest, exposer) do
    manifest
    |> Map.get(exposer, %{"routes" => []})
    |> Map.get("routes", [])
  end
end
