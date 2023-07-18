defmodule LenraWeb.UserController do
  use LenraWeb, :controller

  alias Lenra.Accounts

  def current_user(conn, _params) do
    with user <- LenraWeb.Auth.current_resource(conn) do
      reply(conn, user)
    end
  end

  def validate_user(conn, params) do
    with user <- LenraWeb.Auth.current_resource(conn),
         {:ok, %{updated_user: updated_user}} <- Accounts.validate_user(user, params["code"]) do
      conn
      |> reply(updated_user)
    end
  end

  def resend_registration_token(conn, _params) do
    with user <- LenraWeb.Auth.current_resource(conn),
         {:ok, _any} <- Accounts.resend_registration_code(user) do
      reply(conn)
    end
  end

  def validate_dev(conn, _params) do
    with user <- LenraWeb.Auth.current_resource(conn),
         {:ok, %{updated_user: updated_user}} <- Accounts.validate_dev(user) do
      conn
      |> reply(updated_user)
    end
  end

  def change_password(conn, params) do
    with user <- LenraWeb.Auth.current_resource(conn),
         {:ok, _} <- Accounts.update_user_password(user, params) do
      reply(conn)
    end
  end

  # Keep comment for future PR to restore them
  # def change_lost_password(conn, params) do
  #   with {:ok, user} <- get_user_with_email(params["email"]),
  #        {:ok, _password} <- Accounts.update_user_password_with_code(user, params) do
  #     reply(conn)
  #   else
  #     # Here we return :no_such_password_code instead of :incorrect_email
  #     # to avoid leaking whether an email address exists on Lenra
  #     {:error, :incorrect_email} -> BusinessError.no_such_password_code_tuple()
  #     error -> error
  #   end
  # end

  # Keep comment for future PR to restore them
  # def send_lost_password_code(conn, params) do
  #   case get_user_with_email(params["email"]) do
  #     {:ok, user} -> Accounts.send_lost_password_code(user)
  #     # Here we do not return errors to avoid brute force of error messages
  #     _error -> nil
  #   end

  #   # This is an intended behavior.
  #   # If the email does not exists, we should not return an error to the client.
  #   # Otherwise it gives an information to hackers and allow brutforce
  #   reply(conn)
  # end

  # defp get_user_with_email(nil), do: BusinessError.incorrect_email_tuple()

  # defp get_user_with_email(email) do
  #   case Repo.get_by(User, email: String.downcase(email)) do
  #     nil -> BusinessError.incorrect_email_tuple()
  #     user -> {:ok, user}
  #   end
  # end
end
