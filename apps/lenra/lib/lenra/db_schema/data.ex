defmodule Lenra.Data do
  @moduledoc """
    The datastore schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{Datastore, Data, Refs}

  schema "datas" do
    belongs_to(:datastore, Datastore)
    has_one(:refby, Refs, foreign_key: :referencer)
    has_one(:refto, Refs, foreign_key: :referenced)

    field(:data, :map)

    timestamps()
  end

  def changeset(dataspace, params \\ %{}) do
    dataspace
    |> cast(params, [:data])
    |> validate_required([:data])
    |> foreign_key_constraint(:datastore_id)
  end

  @spec new(any, :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}) :: Ecto.Changeset.t()
  def new(datastore_id, params \\ %{}) do
    %Data{datastore_id: datastore_id}
    |> Data.changeset(params)
  end
end
