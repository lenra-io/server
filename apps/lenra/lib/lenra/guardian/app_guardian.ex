defmodule Lenra.AppGuardian do
  @moduledoc """
    Lenra.Guardian handle the callback operations to generate and verify the token.
  """

  use Guardian, otp_app: :lenra

  alias ApplicationRunner.{SessionManager, SessionManagers}

  def subject_for_token(session_pid, _claims) do
    {:ok, to_string(inspect(session_pid))}
  end

  def resource_from_claims(%{"sub" => session_id}) do
    with {:ok, session_pid} <- SessionManagers.fetch_session_manager_pid(session_id),
         session_assigns <- SessionManager.get_assigns(session_pid) do
      {:ok, session_assigns}
    end
  end

  def verify_claims(claims, _option) do
    with {:ok, _id} <- SessionManagers.fetch_session_manager_pid(claims["sub"]) do
      {:ok, claims}
    end
  end

  def on_verify(claims, token, _options) do
    # TODO see if we can pass id in option, from verify_claims
    with {:ok, session_pid} <- SessionManagers.fetch_session_manager_pid(claims["sub"]),
         session_assigns <- SessionManager.get_assigns(session_pid) do
      IO.puts(session_assigns)

      case extract_token(session_assigns) == token do
        true ->
          SessionManager.set_assigns(session_pid, Lenra.AppGuardian.revoke(token))
          {:ok, claims}

        false ->
          {:error, :invalid_token}
      end
    end
  end

  defp extract_token([%{token: token}]) do
    token
  end
end
