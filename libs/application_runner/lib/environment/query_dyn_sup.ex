defmodule ApplicationRunner.Environment.QueryDynSup do
  @moduledoc """
    This module is responsible to start the QueryServer for a given env_id.
    If the query server is already started, it act like it just started.
    It also add the QueryServer to the correct group after it started it.
  """
  use DynamicSupervisor
  use SwarmNamed

  alias ApplicationRunner.Environment.QueryServer

  require Logger

  def start_link(opts) do
    Logger.info("Start #{__MODULE__}")
    Logger.debug("#{__MODULE__} start_link with #{inspect(opts)}")
    env_id = Keyword.fetch!(opts, :env_id)
    res = DynamicSupervisor.start_link(__MODULE__, :ok, name: get_full_name(env_id))

    Logger.debug("#{__MODULE__} start_link exit with #{inspect(res)}")

    res
  end

  @impl true
  def init(_init_arg) do
    Logger.debug("#{__MODULE__} init")

    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec ensure_child_started(term(), String.t() | nil, map() | nil, map() | nil, map(), map()) ::
          {:ok, pid()} | {:error, term()}
  def ensure_child_started(env_id, coll, query_parsed, query_transformed, projection, options \\ %{}) do
    Logger.debug(
      "#{__MODULE__} ensure query server started for #{inspect([env_id, coll, query_parsed, query_transformed])}"
    )

    case start_child(env_id, coll, query_parsed, query_transformed, projection, options) do
      {:ok, pid} ->
        Logger.info("ApplicationRunner.Environment.QueryServer started")
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      err ->
        Logger.critical(inspect(err))
        err
    end
  end

  defp start_child(env_id, coll, query_parsed, query_transformed, projection, options) do
    init_value = [
      query_parsed: query_parsed,
      query_transformed: query_transformed,
      coll: coll,
      env_id: env_id,
      projection: projection,
      options: options
    ]

    DynamicSupervisor.start_child(get_full_name(env_id), {QueryServer, init_value})
  end
end
