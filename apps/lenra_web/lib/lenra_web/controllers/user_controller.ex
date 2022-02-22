defmodule LenraWeb.UserController do
  use LenraWeb, :controller

  alias Lenra.Guardian.Plug
  alias Lenra.{PasswordServices, Repo, User, UserServices}
  alias LenraWeb.TokenHelper

  def register(conn, params) do
    with {:ok, %{inserted_user: user}} <- UserServices.register(params) do
      conn
      |> TokenHelper.assign_access_and_refresh_token(user)
      |> assign_data(:user, user)
      |> reply
    end
  end

  def login(conn, params) do
    with {:ok, user} <- UserServices.login(params["email"], params["password"]) do
      conn
      |> TokenHelper.assign_access_and_refresh_token(user)
      |> assign_data(:user, user)
      |> reply
    end
  end

  def refresh(conn, _params) do
    access_token =
      conn
      |> Plug.current_token()
      |> TokenHelper.create_access_token()

    conn
    |> TokenHelper.assign_access_token(access_token)
    |> assign_data(:user, Plug.current_resource(conn))
    |> reply
  end

  def validate_user(conn, params) do
    with user <- Plug.current_resource(conn),
         {:ok, %{updated_user: updated_user}} <- UserServices.validate_user(user, params["code"]) do
      conn
      |> TokenHelper.revoke_current_refresh()
      |> TokenHelper.assign_access_and_refresh_token(updated_user)
      |> assign_data(:user, updated_user)
      |> reply
    end
  end

  def validate_dev(conn, params) do
    with user <- Plug.current_resource(conn),
         {:ok, %{updated_user: updated_user}} <- UserServices.validate_dev(user, params["code"]) do
      conn
      |> TokenHelper.revoke_current_refresh()
      |> TokenHelper.assign_access_and_refresh_token(updated_user)
      |> assign_data(:user, updated_user)
      |> reply
    end
  end

  def logout(conn, _params) do
    conn
    |> TokenHelper.revoke_current_refresh()
    |> Plug.clear_remember_me()
    |> reply()
  end

  def password_modification(conn, params) do
    with user <- Plug.current_resource(conn),
         {:ok, _} <- PasswordServices.update_password(user, params) do
      reply(conn)
    end
  end

  defp get_user_with_email(nil), do: {:error, :email_incorrect}

  defp get_user_with_email(email) do
    case Repo.get_by(User, email: String.downcase(email)) do
      nil -> {:error, :email_incorrect}
      user -> {:ok, user}
    end
  end

  def password_lost_modification(conn, params) do
    with {:ok, user} <- get_user_with_email(params["email"]),
         {:ok, password_code} <- PasswordServices.check_password_code_valid(user, params["code"]),
         {:ok, _password} <- PasswordServices.update_lost_password(user, password_code, params) do
      reply(conn)
    else
      # Here we return :no_such_password_code instead of :email_incorrect
      # to avoid leaking whether an email address exists on Lenra
      {:error, :email_incorrect} -> {:error, :no_such_password_code}
      error -> error
    end
  end

  def password_lost_code(conn, params) do
    case get_user_with_email(params["email"]) do
      {:ok, user} -> PasswordServices.send_password_code(user)
      _error -> nil
    end

    # This is an intended behavior.
    # If the email does not exists, we should not return an error to the client.
    # Otherwise it gives an information to hackers and allow brutforce
    reply(conn)
  end
end
