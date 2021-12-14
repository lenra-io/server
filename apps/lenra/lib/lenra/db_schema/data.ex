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
    |> cast(params, [])
    |> validate_required([:data])
    |> foreign_key_constraint(:datastore_id)
  end

  def new(datastore_id, data) do
    %Data{datastore_id: datastore_id, data: data}
    |> Data.changeset()
  end
end
