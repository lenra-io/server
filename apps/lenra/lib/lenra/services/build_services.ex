defmodule Lenra.BuildServices do
  @moduledoc """
    The service that manages the different possible actions on a build.
  """
  import Ecto.Query

  alias Lenra.{
    Build,
    GitlabApiServices,
    LenraApplication,
    LenraApplicationServices,
    Repo
  }

  require Logger

  def all(app_id) do
    Repo.all(from(b in Build, where: b.application_id == ^app_id))
  end

  def get(build_id) do
    Repo.get(Build, build_id)
  end

  def fetch(build_id) do
    Repo.fetch(Build, build_id)
  end

  def fetch_by(clauses) do
    Repo.fetch_by(Build, clauses)
  end

  defp create(creator_id, app_id, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.run(:build_number, fn repo, _result ->
      {:ok,
       repo.one(
         from(b in Build,
           select: (b.build_number |> max() |> coalesce(0)) + 1,
           where: b.application_id == ^app_id
         )
       )}
    end)
    |> Ecto.Multi.insert(:inserted_build, fn %{build_number: build_number} ->
      Build.new(creator_id, app_id, build_number, params)
    end)
  end

  def create_and_trigger_pipeline(creator_id, app_id, params) do
    with {:ok, %LenraApplication{} = app} <- LenraApplicationServices.fetch(app_id),
    {:ok, %Lenra.Repository{} = repository} <- Lenra.RepositoryServices.fetch_by(application_id: app_id) do
      creator_id
      |> create(app.id, params)
      |> Ecto.Multi.run(:gitlab_pipeline, fn _repo, %{inserted_build: %Build{} = build} ->
        GitlabApiServices.create_pipeline(
          app.service_name,
          repository.url,
          repository.branch,
          build.id,
          build.build_number
        )
      end)
      |> Repo.transaction()
    end
  end

  def update(build, params) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_build, Build.update(build, params))
    |> Repo.transaction()
  end

  @spec delete((map -> %{optional(atom) => any}) | struct) :: Ecto.Multi.t()
  def delete(build) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:deleted_build, build)
  end
end
