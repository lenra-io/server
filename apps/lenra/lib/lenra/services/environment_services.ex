defmodule Lenra.EnvironmentServices do
  @moduledoc """
    The service that manages the different possible actions on an environment.
  """
  import Ecto.Query
  alias ApplicationRunner.Datastore
  alias Lenra.{Environment, Repo}
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
    |> handle_create
    |> Repo.transaction()
  end

  def create_with_app(multi, creator_id, params) do
    multi
    |> Ecto.Multi.insert(:inserted_env, fn %{inserted_application: app} ->
      Environment.new(app.id, creator_id, nil, params)
    end)
    |> handle_create
  end

  defp handle_create(multi) do
    multi
    |> Ecto.Multi.insert(:inserted_datastore, fn %{inserted_env: env} ->
      Datastore.new(env.id, %{"name" => "UserDatas"})
    end)
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
