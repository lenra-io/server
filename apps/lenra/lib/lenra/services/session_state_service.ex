defmodule Lenra.SessionStateServices do
  @moduledoc """
    Lenra.Sessionstate handle all operation for session state.
  """

  alias ApplicationRunner.SessionManager
  alias Lenra.AppGuardian

  def create_and_assign_token(session_id) do
    with {:ok, session_assigns} <- SessionManager.fetch_assigns(session_id),
         {:ok, token, _claims} <- AppGuardian.encode_and_sign(session_id, %{type: "session"}),
         :ok <- SessionManager.set_assigns(session_id, Map.merge(session_assigns, %{token: token})) do
      {:ok, token}
    end
  end

  def revoke_token(session_id, token) do
    with {:ok, session_assigns} <- SessionManager.fetch_assigns(session_id),
         {:ok, revoked_token} <- AppGuardian.revoke(token) do
      SessionManager.set_assigns(session_id, Map.merge(session_assigns, %{token: revoked_token}))
    end
  end
end
