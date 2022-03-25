defmodule Lenra.DatastoreServices do
  @moduledoc """
    The service that manages the different possible actions on a datastore.
  """
  alias Lenra.{Datastore, Repo}
  require Logger

  @doc """
    Gets the datastore.

    Returns `nil` if the datastore does not exist.
    Returns a `Lenra.Datastore` if the datastore exists.
  """
  def get_by(clauses) do
    Repo.get_by(Datastore, clauses)
  end
end
