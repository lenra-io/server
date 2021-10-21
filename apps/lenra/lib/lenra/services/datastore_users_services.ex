defmodule Lenra.DatastoreUsersServices do
  @moduledoc """
    The service that manages the different possible actions on a datastore.
  """
  require Logger

  alias Lenra.{Repo, Datastore, DatastoreUsers}

  @doc """
    Gets the DatastoreUsers.

    Returns `nil` if the DatastoreUsers does not exist.
    Returns a `Lenra.DatastoreUsers` if the DatastoreUsers exists.
  """
  def get_by(clauses) do
    Repo.get_by(DatastoreUsers, clauses)
  end

  @doc """
  Creates or updates the data in the corresponding datastore.

  Returns `{:ok, struct}` if the data was successfully inserted or updated.
  Returns `{:error, changeset}` if the data could not be inserted or updated.
  """
  def create(user, app) do
    DatastoreUsers.new(user.id, app.id)
    |> Repo.insert()
  end

  def delete(datastore) do
    Repo.delete(datastore)
  end
end
