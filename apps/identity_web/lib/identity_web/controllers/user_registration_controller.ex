defmodule IdentityWeb.UserRegistrationController do
  use IdentityWeb, :controller

  alias Lenra.Accounts
  alias Lenra.Accounts.User
  alias Lenra.Accounts.Password
  alias IdentityWeb.UserAuth
  alias LenraWeb.TokenHelper

  def new(conn, _params) do
    # changeset = Accounts.Password.changeset(%Password{user: %User{}})
    changeset = Accounts.User.registration_changeset(%User{password: [%Password{}]}, %{})
    IO.inspect(changeset)
    IO.inspect(changeset.data)
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    IO.inspect(user_params)

    case Accounts.register_user(user_params) do
      {:ok, %{inserted_user: user}} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> TokenHelper.assign_access_and_refresh_token(user)
        |> redirect(to: signed_in_path(conn))

      {:error, :inserted_user, %Ecto.Changeset{} = changeset, _} ->
        IO.inspect("Inserted_user")
        IO.inspect(changeset)
        IO.inspect(changeset.data)
        render(conn, "new.html", changeset: changeset)

      {:error, :password, changeset, _} ->
        IO.inspect("Inserted_password")
        IO.inspect(changeset)
        IO.inspect(changeset.data)

        render(conn, "new.html", changeset: changeset)
    end
  end

  defp signed_in_path(_conn), do: "/"
end
