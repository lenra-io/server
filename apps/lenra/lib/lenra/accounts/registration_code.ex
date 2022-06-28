defmodule Lenra.Accounts.RegistrationCode do
  @moduledoc """
    The registration_code schema.
  """
  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.Accounts.User

  schema "registration_codes" do
    field(:code, :string)
    belongs_to(:user, User)
    timestamps()
  end

  @spec changeset(
          {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
          :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: Ecto.Changeset.t()
  def changeset(registration_code, params \\ %{}) do
    registration_code
    |> cast(params, [:code])
    |> validate_required([:code])
    |> unique_constraint([:user_id])
    |> validate_length(:code, min: 8, max: 8)
  end

  def new(user, code) do
    user
    |> Ecto.build_assoc(:registration_code)
    |> changeset(%{code: code})
  end
end
