defmodule Lenra.Datastore do
  @moduledoc """
    The datastore schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{User, Datastore, Dataspace}

  schema "datastores" do
    belongs_to(:owner, User)
    belongs_to(:dataspace, Dataspace)
    field(:data, :map)
    timestamps()
  end

  def changeset(datastore, params \\ %{}) do
    datastore
    |> cast(params, [:data])
    |> validate_required([:data, :dataspace_id])
    |> foreign_key_constraint(:owner_id)
    |> foreign_key_constraint(:dataspace_id)
  end

  def new(owner_id, dataspace_id, data) do
    %Datastore{owner_id: owner_id, dataspace_id: dataspace_id, data: data}
    |> Datastore.changeset()
  end
end
