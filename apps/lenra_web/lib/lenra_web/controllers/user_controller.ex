defmodule LenraWeb.UserController do
  use LenraWeb, :controller

  alias Lenra.Accounts
  alias Lenra.Accounts.User
  alias Lenra.Repo
  alias LenraWeb.Guardian.Plug
  alias LenraWeb.TokenHelper

  def register(conn, params) do
    with {:ok, %{inserted_user: user}} <- Accounts.register_user(params) do
      conn
      |> TokenHelper.assign_access_and_refresh_token(user)
      |> assign_data(user)
      |> reply
    end
  end

  def login(conn, params) do
    with {:ok, user} <- Accounts.login_user(params["email"], params["password"]) do
      conn
      |> TokenHelper.assign_access_and_refresh_token(user)
      |> assign_data(user)
      |> reply
    end
  end

  def refresh_token(conn, _params) do
    {:ok, access_token} =
      conn
      |> Plug.current_token()
      |> TokenHelper.create_access_token()

    conn
    |> TokenHelper.assign_access_token(access_token)
    |> assign_data(Plug.current_resource(conn))
    |> reply
  end

  def validate_user(conn, params) do
    with user <- Plug.current_resource(conn),
         {:ok, %{updated_user: updated_user}} <- Accounts.validate_user(user, params["code"]) do
      conn
      |> TokenHelper.revoke_current_refresh()
      |> TokenHelper.assign_access_and_refresh_token(updated_user)
      |> assign_data(updated_user)
      |> reply
    end
  end

  def validate_dev(conn, params) do
    with user <- Plug.current_resource(conn),
         {:ok, %{updated_user: updated_user}} <- Accounts.validate_dev(user, params["code"]) do
      conn
      |> TokenHelper.revoke_current_refresh()
      |> TokenHelper.assign_access_and_refresh_token(updated_user)
      |> assign_data(updated_user)
      |> reply
    end
  end

  def logout(conn, _params) do
    conn
    |> TokenHelper.revoke_current_refresh()
    |> Plug.clear_remember_me()
    |> reply()
  end

  def change_password(conn, params) do
    with user <- Plug.current_resource(conn),
         {:ok, _} <- Accounts.update_user_password(user, params) do
      reply(conn)
    end
  end

  def change_lost_password(conn, params) do
    with {:ok, user} <- get_user_with_email(params["email"]),
         {:ok, _password} <- Accounts.update_user_password_with_code(user, params) do
      reply(conn)
    else
      # Here we return :no_such_password_code instead of :incorrect_email
      # to avoid leaking whether an email address exists on Lenra
      {:error, :incorrect_email} -> {:error, :no_such_password_code}
      error -> error
    end
  end

  def send_lost_password_code(conn, params) do
    case get_user_with_email(params["email"]) do
      {:ok, user} -> Accounts.send_lost_password_code(user)
      # Here we do not return errors to avoid brute force of error messages
      _error -> nil
    end

    # This is an intended behavior.
    # If the email does not exists, we should not return an error to the client.
    # Otherwise it gives an information to hackers and allow brutforce
    reply(conn)
  end

  defp get_user_with_email(nil), do: {:error, :incorrect_email}

  defp get_user_with_email(email) do
    case Repo.get_by(User, email: String.downcase(email)) do
      nil -> {:error, :incorrect_email}
      user -> {:ok, user}
    end
  end
end
