defmodule ApplicationRunner.Session do
  @moduledoc """
    ApplicationRunner.Session manage all lenra session fonctionnality
  """

  alias ApplicationRunner.Session

  @doc """
    Start a Session Supervisor for the given session_state (session_id must be unique),
    Make sure the environment Supervisor is started for the given `env_state`,
    if the environment is not started, it is started with the given `env_state`.

    Returns {:ok, session_pid} | {:error, tuple()}
  """
  defdelegate start_session(session_state, env_state), to: Session.DynamicSupervisor

  defdelegate stop_session(env_id, session_id), to: Session.DynamicSupervisor

  @doc """
    Send a sync call to the application,
    The call will run listeners for the given code `code` and `event`

    Returns :ok
  """
  defdelegate send_client_event(session_id, code, event), to: ApplicationRunner.EventHandler
end
