defmodule Lenra.AppGuardian do
  @moduledoc """
    Lenra.Guardian handle the callback operations to generate and verify the token.
  """

  use Guardian, otp_app: :lenra

  alias ApplicationRunner.{SessionManagers, SessionManager}

  def subject_for_token(session_pid, _claims) do
    {:ok, to_string(session_pid)}
  end

  def resource_from_claims(%{"sub" => session_pid}) do
    {:ok, session_pid}
  end

  def verify_claims(claims, _option) do
    with {:ok, _id} <- SessionManagers.fetch_session_manager_pid(claims["sub"]) do
      {:ok, claims}
    end
  end

  def on_verify(claims, token, _options) do
    # TODO see if we can pass id in option, from verify_claims
    with {:ok, _id} <- SessionManagers.fetch_session_manager_pid(claims["sub"]),
         :ok <- SessionManager.verify_token(claims["sub"], token) do
      {:ok, claims}
    end
  end
end
