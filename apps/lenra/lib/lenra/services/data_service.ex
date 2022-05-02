defmodule Lenra.DataServices do
  @moduledoc """
    The service that manages application data.
  """
  import Ecto.Query, only: [from: 2]

  alias Lenra.Repo
  alias ApplicationRunner.{AST.EctoParser, AST.Parser, AST.Query, Data, DataServices, Datastore, UserData}

  def get(ds_name, id) do
    select =
      from(d in Data,
        join: ds in Datastore,
        on: d.datastore_id == ds.id,
        where: d.id == ^id and ds.name == ^ds_name,
        select: d
      )

    select
    |> Repo.one()
  end

  def query(env_id, user_id, %Query{} = query) do
    user_data_id = get_user_data_id(env_id, user_id)

    query
    |> EctoParser.to_ecto(env_id, user_data_id)
    |> Repo.all()
  end

  def query(env_id, user_id, query) do
    user_data_id = get_user_data_id(env_id, user_id)

    query
    |> Parser.from_json()
    |> EctoParser.to_ecto(env_id, user_data_id)
    |> Repo.all()
  end

  defp get_user_data_id(env_id, user_id) do
    select =
      from(d in Data,
        join: ud in UserData,
        on: ud.data_id == d.id,
        join: ds in Datastore,
        on: d.datastore_id == ds.id,
        where: ud.user_id == ^user_id and ds.environment_id == ^env_id,
        select: d.id
      )

    select
    |> Repo.one()
  end

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

  def update(params) do
    params
    |> ApplicationRunner.DataServices.update()
    |> Repo.transaction()
  end

  def delete(data_id) do
    data_id
    |> DataServices.delete()
    |> Repo.transaction()
  end
end
