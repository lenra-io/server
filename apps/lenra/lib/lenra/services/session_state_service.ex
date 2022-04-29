defmodule Lenra.SessionStateServices do
  @moduledoc """
    Lenra.Sessionstate handle all operation for session state.
  """

  alias Lenra.AppGuardian
  alias ApplicationRunner.SessionSupervisor

  def create_token(session_id, user_id, env_id) do
    with {:ok, token, _claims} <-
           AppGuardian.encode_and_sign(session_id, %{type: "session", user_id: user_id, env_id: env_id}) do
      {:ok, token}
    end
  end

  def fetch_token(session_id) do
    with agent <- SessionSupervisor.fetch_module_pid!(session_id, Lenra.TokenAgent) do
      Agent.get(agent, fn state -> state end)
    end
  end
end
