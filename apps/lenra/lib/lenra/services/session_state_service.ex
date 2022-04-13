defmodule Lenra.SessionStateServices do
  @moduledoc """
    Lenra.Sessionstate handle all operation for session state.
  """

  alias Lenra.AppGuardian
  alias Lenra.SessionAgent

  def create_and_assign_token(session_id, user_id, env_id) do
    with {:ok, token, _claims} <-
           AppGuardian.encode_and_sign(session_id, %{type: "session", user_id: user_id, env_id: env_id}),
         :ok <- SessionAgent.add_token(session_id, token) do
      {:ok, token}
    end
  end

  def revoke_token(session_id) do
    SessionAgent.revoke_token(session_id)
  end
end
