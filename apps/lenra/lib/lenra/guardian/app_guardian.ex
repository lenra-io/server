defmodule Lenra.AppGuardian do
  @moduledoc """
    Lenra.Guardian handle the callback operations to generate and verify the token.
  """

  use Guardian, otp_app: :lenra
  require Logger

  alias Lenra.{Environment, Repo, SessionAgent, User, SessionStateServices, EnvironmentStateServices}

  def subject_for_token(session_pid, _claims) do
    {:ok, to_string(session_pid)}
  end

  def resource_from_claims(%{"user_id" => user_id, "env_id" => env_id}) do
    with env <- Repo.get(Environment, env_id),
         user <- Repo.get(User, user_id) do
      {:ok, %{environment: env, user: user}}
    end
  end

  def on_verify(claims, token, _options) do
    if get_app_token(claims) ==
         token do
      {:ok, claims}
    else
      {:error, :invalid_token}
    end
  end

  defp get_app_token(claims) do
    IO.inspect(claims)

    case claims["type"] do
      "session" ->
        {:ok, token} = SessionStateServices.fetch_token(String.to_integer(claims["sub"]))
        token

      "env" ->
        {:ok, token} = EnvironmentStateServices.fetch_token(String.to_integer(claims["sub"]))
        IO.inspect({:env, token})
        token

      _err ->
        :error
    end
  end
end
