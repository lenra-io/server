defmodule Lenra.AppGuardian do
  @moduledoc """
    Lenra.Guardian handle the callback operations to generate and verify the token.
  """

  use Guardian, otp_app: :lenra

  alias ApplicationRunner.SessionManagers

  def subject_for_token(session_pid, _claims) do
    {:ok, to_string(session_pid)}
  end

  def resource_from_claims(%{"sub" => session_pid}) do
  end

  def verify_claims(claims, option) do
    IO.inspect(claims)
    IO.inspect(option)
    {:ok, claims}
  end
end
