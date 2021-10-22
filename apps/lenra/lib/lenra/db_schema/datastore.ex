defmodule Lenra.Datastore do
  @moduledoc """
    The datastore schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{User, DatastoreUsers, LenraApplication, Datastore}

  schema "datastores" do
    belongs_to(:owner, User)
    has_many(:datastore_users, DatastoreUsers)
    belongs_to(:application, LenraApplication)
    field(:data, :map)
    timestamps()
  end

  def changeset(datastore, params \\ %{}) do
    datastore
    |> cast(params, [:data])
    |> validate_required([:data])
    |> foreign_key_constraint(:owner_id)
    |> foreign_key_constraint(:application_id) 
  end

  def new(owner_id, application_id, data) do
    %Datastore{owner_id: owner_id, application_id: application_id, data: data}
    |> Datastore.changeset()
  end
end
