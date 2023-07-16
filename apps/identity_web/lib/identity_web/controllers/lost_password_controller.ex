defmodule IdentityWeb.LostPasswordController do
  alias Lenra.Legal
  use IdentityWeb, :controller

  alias Lenra.Accounts
  alias Lenra.Accounts.Password
  alias Lenra.Accounts.User

  def enter_email(conn, _params) do
    render(conn, "enter-email.html", error_message: nil)
  end

  def send_lost_password_code(conn, %{"email" => email}) do
    case get_user_with_email(params["email"]) do
      {:ok, user} -> Accounts.send_lost_password_code(user)
      # Here we do not return errors to avoid brute force of error messages
      _error -> nil
    end

    # This is an intended behavior.
    # If the email does not exists, we should not return an error to the client.
    # Otherwise it gives an information to hackers and allow brutforce
    reply(conn)
    case Accounts.get_user_by_email(email) do
      nil ->
        render(conn, "enter-email.html", error_message: "Email not found")
      user ->
        Accounts.send_lost_password_code(user)
        render(conn, "enter-email.html", error_message: "Email sent")
    end
  end
end
