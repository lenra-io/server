defmodule Lenra.DataServices do
  @moduledoc """
    The service that manages application data.
  """
  alias Lenra.Repo
  alias ApplicationRunner.{Data, DataServices, Datastore, UserData}
  import Ecto.Query, only: [from: 2]

  def create(environment_id, params) do
    DataServices.create(environment_id, params)
    |> Repo.transaction()
  end

  def create_and_link(user_id, environment_id, params) do
    DataServices.create(environment_id, params)
    |> Ecto.Multi.run(:user_data, fn repo, %{inserted_data: %Data{} = data} ->
      repo.insert(UserData.new(%{user_id: user_id, data_id: data.id}))
    end)
    |> Repo.transaction()
  end

  def update(data_id, params) do
    DataServices.update(data_id, params)
    |> Repo.transaction()
  end

  def delete(data_id) do
    DataServices.delete(data_id)
    |> Repo.transaction()
  end

  def get_old_data(user_id, environement_id) do
    from(d in Data,
      join: u in UserData,
      on: d.id == u.data_id,
      join: ds in Datastore,
      on: ds.id == d.datastore_id,
      where: u.user_id == ^user_id and ds.environment_id == ^environement_id and ds.name == "UserDatas",
      select: d
    )
    |> Repo.one()
  end

  def upsert_data(user_id, environment_id, data) do
    get_old_data(user_id, environment_id)
    |> case do
      nil ->
        create_and_link(user_id, environment_id, data)

      old_data_id ->
        update(old_data_id.id, data)
    end
  end
end
