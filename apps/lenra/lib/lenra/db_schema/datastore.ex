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
    |> unique_constraint(:user_application_unique, name: :datastores_user_id_application_id_index)
    |> foreign_key_constraint(:owner_id)
    |> foreign_key_constraint(:application_id) 
  end

  def new(owner_id, application_id, data) do
    %Datastore{owner_id: owner_id, application_id: application_id}
    |> Datastore.changeset(data)
  end
end
