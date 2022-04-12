defmodule Lenra.DatastoreServices do
  @moduledoc """
    The service that manages the different possible actions on a datastore.
  """
  alias ApplicationRunner.{Datastore, DatastoreServices}
  alias Lenra.Repo
  require Logger

  def create(environment_id, params) do
    environment_id
    |> DatastoreServices.create(params)
    |> Repo.transaction()
  end

  def create_environment_user_datastore(multi) do
    multi
    |> Ecto.Multi.insert(:inserted_datastore, fn %{inserted_env: env} ->
      Datastore.new(env.id, %{"name" => "UserDatas"})
    end)
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
