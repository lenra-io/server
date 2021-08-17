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

    Returns `%{:ok, action}` with :old_data nil if the datastore does not exist.
    Returns a `%{:ok, action}` with data assign to :old_data if the datastore exists.
  """
  def assign_old_data(action, application_id) do
    case get_by(user_id: action.user_id, application_id: application_id) do
      nil -> {:ok, action}
      datastore -> {:ok, %{action | old_data: datastore.data}}
    end
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
