defmodule Lenra.DatastoreServices do
  @moduledoc """
    The service that manages the different possible actions on a datastore.
  """
  require Logger

  alias Lenra.{Repo, Datastore}

  @doc """
    Gets the datastore.

    Returns `nil` if the datastore does not exist.
    Returns a `Lenra.Datastore` if the datastore exists.
  """
  def get_by(clauses) do
    Repo.get_by(Datastore, clauses)
  end

  @doc """
    Gets the datastore data

    Returns the data.
    data is nil if the data does not exists for this user/app
  """
  def get_old_data(user_id, application_id) do
    get_by(user_id: user_id, application_id: application_id)
  end

  @doc """
  Creates or updates the data in the corresponding datastore.

  Returns `{:ok, struct}` if the data was successfully inserted or updated.
  Returns `{:error, changeset}` if the data could not be inserted or updated.
  """
  def upsert_data(user_id, application_id, data) do
    Datastore.new(user_id, application_id, data)
    |> Repo.insert(
      on_conflict: [set: [data: data]],
      conflict_target: [:user_id, :application_id]
    )
  end
end
