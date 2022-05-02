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
      Datastore.new(env.id, %{"name" => "_users"})
    end)
  end

  def delete(ds_name, env_id) do
    Datastore
    |> Repo.get_by(environment_id: env_id, name: ds_name)
    |> case do
      nil ->
        {:error, :datastore_not_found}

      datastore ->
        datastore.id
        |> DatastoreServices.delete()
        |> Repo.transaction()
    end
  end
end
