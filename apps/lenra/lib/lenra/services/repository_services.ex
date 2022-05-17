defmodule Lenra.RepositoryServices do
  @moduledoc """
    The service that manages possible actions on a repository.
  """

  alias Lenra.{
    Repo,
    Repository
  }

  require Logger

  def fetch(repository_id) do
    Repo.fetch(Repository, repository_id)
  end

  def fetch_by(clauses, error \\ {:error, :error_404}) do
    Repo.fetch_by(Repository, clauses, error)
  end

  def create(app_id, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:inserted_repository, Repository.new(app_id, params))
    |> Repo.transaction()
  end

  def update(repository, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_repository, Repository.update(repository, params))
    |> Repo.transaction()
  end

  def delete(repository) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:deleted_repository, repository)
    |> Repo.transaction()
  end
end
