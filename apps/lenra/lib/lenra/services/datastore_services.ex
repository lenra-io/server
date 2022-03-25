defmodule Lenra.DatastoreServices do
  @moduledoc """
    The service that manages the different possible actions on a datastore.
  """
  alias ApplicationRunner.DatastoreServices
  alias Lenra.Repo
  require Logger

  def create(environment_id, params) do
    environment_id
    |> DatastoreServices.create(params)
    |> Repo.transaction()
  end

  def update(datastore_id, params) do
    datastore_id
    |> DatastoreServices.update(params)
    |> Repo.transaction()
  end

  def delete(datastore_id) do
    datastore_id
    |> DatastoreServices.delete()
    |> Repo.transaction()
  end
end
