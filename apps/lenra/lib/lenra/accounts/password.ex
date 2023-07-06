defmodule Lenra.Accounts.Password do
  @moduledoc """
    The password_save shema.
  """
  use Lenra.Schema

  import Ecto.Changeset

  alias Lenra.Accounts.User

  schema "passwords" do
    belongs_to(:user, User)
    field(:password, :string, redact: true)
    timestamps()
  end

  def changeset(password, params \\ %{}) do
    password
    |> cast(params, [:password])
    |> validate_required([:password, :user_id])
    |> validate_password()
    |> put_pass_hash()
  end

  def new_changeset(password, params \\ %{}) do
    password
    |> cast(params, [:password])
    |> validate_required([:password])
    |> validate_password()
    |> put_pass_hash()
  end

  def validate_password(changeset) do
    changeset
    |> unique_constraint(:password)
    |> validate_length(:password, min: 8)
    # |> validate_format(:password, @password_regex)
    |> validate_format(:password, ~r/[a-z]/, message: "should have at least one lower case character")
    |> validate_format(:password, ~r/[A-Z]/, message: "should have at least one upper case character")
    |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/,
      message: "should have at least one digit or punctuation character"
    )
    |> validate_confirmation(:password)
  end

  def new(user, params) do
    user
    |> Ecto.build_assoc(:password)
    |> changeset(params)
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Argon2.add_hash(password, hash_key: :password))
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end
end
