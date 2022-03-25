defmodule Lenra.DataServices do
  @moduledoc """
    The service that manages application data.
  """
  import Ecto.Query, only: [from: 2]

  alias Lenra.Repo
  alias ApplicationRunner.{Data, DataServices, Datastore, UserData}

  def create(environment_id, params) do
    environment_id
    |> DataServices.create(params)
    |> Repo.transaction()
  end

  def create_and_link(user_id, environment_id, params) do
    environment_id
    |> DataServices.create(params)
    |> Ecto.Multi.run(:user_data, fn repo, %{inserted_data: %Data{} = data} ->
      repo.insert(UserData.new(%{user_id: user_id, data_id: data.id}))
    end)
    |> Repo.transaction()
  end

  def update(data_id, params) do
    data_id
    |> DataServices.update(params)
    |> Repo.transaction()
  end

  def delete(data_id) do
    data_id
    |> DataServices.delete()
    |> Repo.transaction()
  end

  def get_old_data(user_id, environment_id) do
    Repo.one(
      from(d in Data,
        join: u in UserData,
        on: d.id == u.data_id,
        join: ds in Datastore,
        on: ds.id == d.datastore_id,
        where: u.user_id == ^user_id and ds.environment_id == ^environment_id and ds.name == "UserDatas",
        select: d
      )
    )
  end

  def upsert_data(user_id, environment_id, data) do
    case get_old_data(user_id, environment_id) do
      nil ->
        create_and_link(user_id, environment_id, data)

      old_data_id ->
        update(old_data_id.id, data)
    end
  end
end
