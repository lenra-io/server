defmodule Lenra.SessionStateServices do
  @moduledoc """
    Lenra.Sessionstate handle all operation for session state.
  """

  alias ApplicationRunner.{SessionManager, SessionManagers}
  alias Lenra.AppGuardian

  def create_and_assign_token(session_id) do
    with {:ok, pid} <- SessionManagers.fetch_session_manager_pid(session_id),
         session_assigns <- SessionManager.get_assigns(pid),
         {:ok, token, _claims} <- AppGuardian.encode_and_sign(session_id, %{type: "session"}) do
      SessionManager.set_assigns(pid, Map.merge(session_assigns, %{token: token}))
      {:ok, token}
    end
  end

  def revoke_token_in_pipe(pipe, session_id, token) do
    with {:ok, pid} <- SessionManagers.fetch_session_manager_pid(session_id),
         session_assigns <- SessionManager.get_assigns(pid),
         {:ok, revoked_token} <- AppGuardian.revoke(token) do
      SessionManager.set_assigns(pid, Map.merge(session_assigns, %{token: revoked_token}))
      pipe
    end
  end
end
