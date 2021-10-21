defmodule Lenra.DatastoreUsers do
  @moduledoc """
    The user list of a datastore relation shema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{Datastore, User, DatastoreUsers}

  schema "datastore_users" do
    belongs_to(:user, User)
    belongs_to(:datastore, Datastore)

    timestamps()
  end

  def changeset(datastore_users) do
    datastore_users
    |> cast(%{}, [])
    |> validate_required([:datastore_id, :user_id])
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:datastore_id)
  end

  def new(app_id, user_id) do
    %DatastoreUsers{datastore_id: app_id, user_id: user_id}
    |> changeset()
  end
end
