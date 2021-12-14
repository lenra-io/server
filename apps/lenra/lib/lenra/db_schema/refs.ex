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
    |> cast(params, [])
    |> validate_required([:referencer_id, :referenced_id])
    |> foreign_key_constraint(:referencer_id)
    |> foreign_key_constraint(:referenced_id)
  end

  def new(referencer, referenced) do
    %Refs{referenced_id: referenced, referencer_id: referencer}
    |> Refs.changeset()
  end
end
