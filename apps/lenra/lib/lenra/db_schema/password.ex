defmodule Lenra.Password do
  @moduledoc """
    The password_save shema.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Lenra.User

  @password_regex ~r/(?=.*[a-z])(?=.*[A-Z])(?=.*\W)/

  schema "passwords" do
    belongs_to(:user, User)
    field(:password, :string, redact: true)
    timestamps()
  end

  def changeset(password, params \\ %{}) do
    password
    |> cast(params, [:password])
    |> validate_required([:password, :user_id])
    |> unique_constraint(:password)
    |> validate_length(:password, min: 8, max: 64)
    |> validate_format(:password, @password_regex)
    |> validate_confirmation(:password)
    |> put_pass_hash()
  end

  def new(user, params) do
    user
    |> Ecto.build_assoc(:password)
    |> changeset(params)
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Argon2.add_hash(password, hash_key: :password))
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: false, changes: %{password: _password}} = changeset) do
    changeset
  end
end
