defmodule ApplicationRunner.Session.DynamicSupervisor do
  @moduledoc """
    This module handles all the sessions for one app.
    This allows to create/recreate/delete sessions for the app and possibly many other operations on sessions.
  """
  use DynamicSupervisor
  use SwarmNamed

  require Logger

  alias ApplicationRunner.Errors.BusinessError
  alias ApplicationRunner.{Environment, Session}

  def start_link(opts) do
    Logger.notice("Start #{__MODULE__}")
    Logger.debug("#{__MODULE__} start_link with opts #{inspect(opts)}")

    env_id = Keyword.fetch!(opts, :env_id)
    DynamicSupervisor.start_link(__MODULE__, :ok, name: get_full_name(env_id))
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Start session for the given env_id and session_id and add it to the :sessions group of swarm.
  This in fact recreate a new process with the given session_id.
  This give the possibility for children modules to recreate their states (cache, UI etc..) if the session_id is the same as before.

  The session should be started with the same session_id if the client socket is disconnected for a short period of time.
  """
  @spec start_session(term(), term()) :: {:error, any} | {:ok, pid()}
  def start_session(session_metadata, env_metadata) do
    with {:ok, _pid} <- Environment.ensure_env_started(env_metadata) do
      case DynamicSupervisor.start_child(
             get_full_name(env_metadata.env_id),
             {Session.Supervisor, session_metadata}
           ) do
        {:error, {:shutdown, {:failed_to_start_child, _module, reason}}} ->
          Logger.critical(BusinessError.cannot_start_session(session_metadata))
          {:error, reason}

        res ->
          Logger.debug("Session start for metadata: #{inspect(session_metadata)}")
          res
      end
    end
  end

  @doc """
    Stop the `Session.Supervisor` with the given `session_id` and return `:ok`.
    If there is no `Session.Supervisor` for the given `session_id`, then return `{:error, :not_started}`
  """
  @spec stop_session(any(), any()) :: :ok | {:error, :app_not_started}
  def stop_session(env_id, session_id) do
    case Swarm.whereis_name(Session.Supervisor.get_name(session_id)) do
      :undefined ->
        Logger.debug("#{__MODULE__} Session not found by swarm for env_id: #{env_id}, session_id: #{session_id}")

        {:error, :app_not_started}

      pid ->
        DynamicSupervisor.terminate_child(get_full_name(env_id), pid)
        |> case do
          :ok ->
            Logger.debug("Session not found for env_id: #{env_id}, session_id: #{session_id}")

          {:error, :not_found} ->
            Logger.warning(
              "#{__MODULE__} DynamicSupervisor could not find Session for env_id: #{env_id}, session_id: #{session_id}"
            )
        end
    end
  end
end
