defmodule Lenra.PasswordCode do
  @moduledoc """
    The password_code schema.
  """
  use Lenra.Schema
  import Ecto.Changeset
  alias Lenra.User

  schema "password_codes" do
    field(:code, :string, null: false)
    belongs_to(:user, User)
    timestamps()
  end

  @spec changeset(
          {map, map}
          | %{
              :__struct__ => atom | %{:__changeset__ => map, optional(any) => any},
              optional(atom) => any
            },
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset(password_code, params \\ %{}) do
    password_code
    |> cast(params, [:code])
    |> validate_required([:code, :user_id])
    |> unique_constraint([:user_id])
    |> validate_length(:code, min: 8, max: 8)
  end

  def new(user, code) do
    user
    |> Ecto.build_assoc(:password_code)
    |> changeset(%{code: code})
  end
end
