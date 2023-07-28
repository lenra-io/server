defmodule Lenra.Accounts.Password do
  @moduledoc """
    The password_save shema.
  """
  use Lenra.Schema

  import Ecto.Changeset

  alias Lenra.Accounts.User

  @lowercase_regex ~r/[a-z]/
  @uppercase_regex ~r/[A-Z]/
  @other_char_regex ~r/[!?@#$£%^&*_0-9 .:;,\/\\-]/
  @min_length 8

  def lowercase_regex, do: @lowercase_regex
  def uppercase_regex, do: @uppercase_regex
  def other_char_regex, do: @other_char_regex
  def min_length, do: @min_length

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
    |> validate_length(:password, min: @min_length, message: "At least %{count} characters")
    |> validate_format(:password, @lowercase_regex, message: "At least 1 lowercase", kind: :lowercase)
    |> validate_format(:password, @uppercase_regex, message: "At least 1 uppercase", kind: :uppercase)
    |> validate_format(:password, @other_char_regex,
      message: "At least 1 digit or punctuation character",
      kind: :digit_or_punctuation
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
