defmodule Lenra.DataServices do
  @moduledoc """
    The service that manages application data.
  """
  import Ecto.Query, only: [from: 2]

  alias Lenra.Repo

  alias ApplicationRunner.{
    AST.EctoParser,
    AST.Parser,
    AST.Query,
    Data,
    DataQueryViewServices,
    DataServices,
    Datastore,
    UserData
  }

  def get(env_id, ds_name, data_id) do
    env_id
    |> DataQueryViewServices.get_one(ds_name, data_id)
    |> Repo.one()
  end

  def get_all(env_id, ds_name) do
    env_id
    |> DataQueryViewServices.get_all(ds_name)
    |> Repo.all()
  end

  def get_me(env_id, user_id) do
    data_id = get_user_data_id(env_id, user_id)

    env_id
    |> DataQueryViewServices.get_one("_users", data_id)
    |> Repo.one()
  end

  def exec_query(_env_id, _user_id, nil) do
    []
  end

  def exec_query(%Query{} = query, env_id, user_id) do
    user_data =
      env_id
      |> ApplicationRunner.UserDataServices.current_user_data_query(user_id)
      |> Repo.one()

    query
    |> EctoParser.to_ecto(env_id, user_data.id)
    |> Repo.all()
  end

  def parse_and_exec_query(query, env_id, user_id) do
    query
    |> Parser.from_json()
    |> exec_query(env_id, user_id)
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
