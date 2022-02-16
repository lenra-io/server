defmodule Lenra.UserEnvironmentAccessServices do
  @moduledoc """
    The service that manages the different possible actions on an environment's user accesses.
  """
  import Ecto.Query
  alias Lenra.{Repo, UserEnvironmentAccess}
  require Logger

  def all(env_id) do
    Repo.all(from(e in UserEnvironmentAccess, where: e.environment_id == ^env_id))
  end

  def get(env_id, user_id) do
    Repo.fetch_by(UserEnvironmentAccess, [environment_id: env_id, user_id: user_id])
  end

  # def fetch(env_id) do
  #   Repo.fetch(Environment, env_id)
  # end

  # def fetch_by(clauses) do
  #   Repo.fetch_by(Environment, clauses)
  # end

  def create(env_id, %{"user_id" => user_id}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:inserted_user_access, UserEnvironmentAccess.changeset(%UserEnvironmentAccess{}, %{user_id: user_id, environment_id: env_id}))
    |> Repo.transaction()
  end

  # def update(env_id, params) do
  #   Ecto.Multi.new()
  #   |> Ecto.Multi.update(:updated_env, Environment.update(env_id, params))
  #   |> Repo.transaction()
  # end

  # def add_user_access(env_id, %{"user_id" => user_id}) do
  #   Ecto.Multi.new()
  #   |> Ecto.Multi.insert(:inserted_user_access, UserEnvironmentAccess.changeset(%UserEnvironmentAccess{}, %{user_id: user_id, environment_id: env_id}))
  #   |> Repo.transaction()
  # end

  # def delete(env) do
  #   Ecto.Multi.new()
  #   |> Ecto.Multi.delete(:deleted_env, env)
  # end
end
