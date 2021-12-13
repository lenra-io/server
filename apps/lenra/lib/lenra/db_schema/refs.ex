defmodule Lenra.Refs do
  @moduledoc """
    The references schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{Data, Refs}

  schema "refs" do
    belongs_to(:referencer, Data)
    belongs_to(:referenced, Data)

    timestamps()
  end

  def changeset(datastore, params \\ %{}) do
    datastore
    |> cast(params, [:referencer, :referenced])
    |> validate_required([:referencer, :referenced])
    |> foreign_key_constraint(:referencer)
    |> foreign_key_constraint(:referenced)
  end

  def new(params) do
    %Refs{}
    |> Refs.changeset(params)
  end
end
