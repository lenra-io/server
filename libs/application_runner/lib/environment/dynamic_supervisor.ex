defmodule ApplicationRunner.Environment.DynamicSupervisor do
  @moduledoc """
    This module manages all the applications.
    It can start/stop an `EnvManager`, get the `EnvManager` process, send a message to all the `EnvManager`, etc..
  """
  use DynamicSupervisor

  alias ApplicationRunner.ApplicationServices
  alias ApplicationRunner.Environment
  alias ApplicationRunner.Errors.BusinessError
  alias ApplicationRunner.Monitor.EnvironmentMonitor
  alias ApplicationRunner.Session
  alias LenraCommon.Errors, as: LC

  require Logger

  @doc false
  def start_link(opts) do
    Logger.debug("#{__MODULE__} start_link with #{inspect(opts)}")
    Logger.notice("Start #{__MODULE__}")
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc false
  @impl true
  def init(_opts) do
    Logger.debug("#{__MODULE__} init")
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_env(term()) ::
          {:error, {:already_started, pid()}} | {:ok, pid()} | {:error, term()}
  defp start_env(%Environment.Metadata{scale_min: scale_min} = env_metadata) do
    Logger.debug("#{__MODULE__} Start Environment Supervisor with env_metadata: #{inspect(env_metadata)}")

    with {:ok, _status} <- ApplicationServices.start_app(env_metadata.function_name, scale_min),
         {:ok, pid} <-
           DynamicSupervisor.start_child(
             __MODULE__,
             {ApplicationRunner.Environment.Supervisor, env_metadata}
           ) do
      {:ok, pid}
    else
      {:error, {:shutdown, {:failed_to_start_child, _module, reason}}} ->
        Logger.critical(
          "#{__MODULE__} failed to start Environment Supervisor with env_metadata: #{inspect(env_metadata)} for reason: #{inspect(reason)}"
        )

        {:error, reason}

      error ->
        error
    end
  end

  @doc """
    Ensure `Environment Supervisor` started.
    This `Environment Supervisor` process will be started in one of the cluster node.
    The children of this `Environment Supervisor` process are restarted from scratch. That means the Sessions process will be lost.
    The app cannot be started twice.
    If the app is not already started, it returns `{:ok, <PID>}`
    If the app is already started, return `{:error, {:already_started, <PID>}}`
  """
  @spec ensure_env_started(term()) :: {:ok, pid} | {:error, term()}
  def ensure_env_started(env_metadata) do
    case start_env(env_metadata) do
      {:ok, pid} ->
        EnvironmentMonitor.monitor(pid, env_metadata)
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        Logger.info("Environment Supervisor already started for metadata: #{inspect(env_metadata)}")

        {:ok, pid}

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
    Stop the `EnvManager` with the given `env_id` and return `:ok`.
    If there is no `EnvManager` for the given `env_id`, then return `{:error, :not_started}`
  """
  @spec stop_env(number()) :: :ok | {:error, LC.BusinessError.t()}
  def stop_env(env_id) do
    Logger.debug("Stopping environment for env_id: #{env_id}")
    name = Environment.Supervisor.get_name(env_id)

    case Swarm.whereis_name(name) do
      :undefined ->
        Logger.error("Failed to find supervision tree for name: #{inspect(name)}")
        BusinessError.env_not_started_tuple()

      pid ->
        Logger.info("Stopping environment supervision tree for name: #{inspect(name)}")
        DynamicSupervisor.terminate_child(__MODULE__, pid)
        # Supervisor.stop(pid)
    end
  end

  def session_stopped(env_id) do
    session_pid = Swarm.whereis_name(Session.DynamicSupervisor.get_name(env_id))

    if is_pid(session_pid) do
      session_pid
      |> Process.alive?()
      |> if do
        session_pid
        |> DynamicSupervisor.count_children()
        |> case do
          %{supervisors: 0} -> stop_env(env_id)
          _any -> :ok
        end
      else
        Logger.critical(
          "Session.DynamicSupervisor for environment #{env_id} is not running. This should not occur, environment stopped"
        )

        stop_env(env_id)
      end
    else
      Logger.warning(
        "Session.DynamicSupervisor pid for environment #{env_id} has not been found. Maybe the session has crashed. Environment stopped"
      )

      stop_env(env_id)
    end
  end
end
