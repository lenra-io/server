defmodule IdentityWeb.UserSessionController do
  use IdentityWeb, :controller

  alias Lenra.Accounts
  alias LenraWeb.TokenHelper

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.login_user(email, password) do
      {:ok, user} ->
        conn
        |> TokenHelper.assign_access_and_refresh_token(user)
        |> redirect(to: signed_in_path(conn))

      _ ->
        render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  defp signed_in_path(_conn), do: "/"
end
