defmodule Lenra.DevCode do
  @moduledoc """
  The DevCode representation in the database.
  A DevCode is a code used to validate a developper account.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.{DevCode, User}

  schema "dev_codes" do
    field(:code, Ecto.UUID)
    belongs_to(:user, User)

    timestamps()
  end

  def changeset(dev_code, params \\ %{}) do
    dev_code
    |> cast(params, [:code, :user_id])
    |> validate_required([:code])
    |> unique_constraint([:code])
    |> unique_constraint([:user_id])
    |> foreign_key_constraint(:user_id)
  end

  def update(dev_code, params) do
    changeset(dev_code, params)
  end

  def new(params) do
    changeset(%DevCode{}, params)
  end
end
