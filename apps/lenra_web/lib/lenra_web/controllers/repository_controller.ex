defmodule LenraWeb.RepositoryController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.AppsController.Policy

  alias Lenra.RepositoryServices

  require Logger

  def index(conn, %{"app_id" => app_id} = _params) do
    with :ok <- allow(conn),
         repository <- RepositoryServices.fetch_by(app_id) do
      conn
      |> assign_data(:repository, repository)
      |> reply
    end
  end

  def create(conn, %{"app_id" => app_id} = params) do
    with :ok <- allow(conn),
         {:ok, %{inserted_repository: repository}} <- RepositoryServices.create(app_id, params) do
      conn
      |> assign_data(:repository, repository)
      |> reply
    end
  end

  def update(conn, %{"app_id" => app_id} = params) do
    with {:ok, repository} <- RepositoryServices.fetch_by(app_id),
         :ok <- allow(conn, repository),
         {:ok, %{updated_repository: repository}} <- RepositoryServices.update(repository, params) do
      conn
      |> assign_data(:updated_repository, repository)
      |> reply
    end
  end

  def delete(conn, %{"app_id" => app_id}) do
    with {:ok, repository} <- RepositoryServices.fetch_by(app_id),
         :ok <- allow(conn, repository),
         {:ok, _} <- RepositoryServices.delete(repository) do
      reply(conn)
    end
  end
end

defmodule LenraWeb.RepositoryController.Policy do
  alias Lenra.{Repository, User}

  @impl Bouncer.Policy
  def authorize(:index, %User{id: user_id}, %Repository{application_id: user_id}), do: true
  def authorize(:create, %User{id: user_id}, %Repository{application_id: user_id}), do: true
  def authorize(:update, %User{id: user_id}, %Repository{application_id: user_id}), do: true
  def authorize(:delete, %User{id: user_id}, %Repository{application_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
