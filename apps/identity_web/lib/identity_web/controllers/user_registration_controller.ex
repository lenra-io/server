defmodule IdentityWeb.UserRegistrationController do
  use IdentityWeb, :controller

  alias Lenra.Accounts
  alias Lenra.Accounts.Password
  alias Lenra.Accounts.User
  alias LenraWeb.TokenHelper

  def new(conn, _params) do
    # changeset = Accounts.Password.changeset(%Password{user: %User{}})
    changeset = Accounts.User.registration_changeset(%User{password: [%Password{}]}, %{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user_new(user_params) do
      {:ok, %{inserted_user: user}} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> TokenHelper.assign_access_and_refresh_token(user)
        |> redirect(to: signed_in_path(conn))

      {:error, :inserted_user, %Ecto.Changeset{} = changeset, _done} ->
        render(conn, "new.html", changeset: changeset)

      {:error, :password, changeset, _done} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  defp signed_in_path(_conn), do: "/"
end
