defmodule Lenra.EnvironmentServices do
  @moduledoc """
    The service that manages the different possible actions on an environment.
  """
  import Ecto.Query
  alias Lenra.{DatastoreServices, Environment, Repo, UserEnvironmentAccess}
  require Logger

  def all(app_id) do
    Repo.all(from(e in Environment, where: e.application_id == ^app_id))
  end

  def get(env_id) do
    Repo.get(Environment, env_id)
  end

  def fetch(env_id) do
    Repo.fetch(Environment, env_id)
  end

  def fetch_by(clauses) do
    Repo.fetch_by(Environment, clauses)
  end

  def create(application_id, creator_id, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:inserted_env, Environment.new(application_id, creator_id, nil, params))
    |> Ecto.Multi.run(:inserted_datastore, fn _repo, %{inserted_env: %Environment{} = env} ->
      DatastoreServices.create(env.id, %{"name" => "UserDatas"})
    end)
    |> Repo.transaction()
  end

  def update(env, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_env, Environment.update(env, params))
    |> Repo.transaction()
  end

  def delete(env) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:deleted_env, env)
  end
end
