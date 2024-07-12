defmodule LenraWeb.DeploymentsController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.DeploymentsController.Policy

  alias Lenra.{Apps, Repo}

  def index(conn, %{"app_id" => app_id}) do
    with {:ok, app} <- Apps.fetch_app(app_id),
         preloaded_app <- Repo.preload(app, main_env: [:environment]),
         :ok <- allow(conn, preloaded_app.main_env.environment) do
      conn
      |> reply(Apps.all_deployments(app.id))
    end
  end

  def create(conn, %{"environment_id" => env_id, "build_id" => build_id} = params) do
    with user <- LenraWeb.Auth.current_resource(conn),
         {:ok, environment} <- Apps.fetch_env(env_id),
         :ok <- allow(conn, environment),
         {:ok, %{inserted_deployment: deployment}} <-
           Apps.create_deployment(env_id, build_id, user.id, params) do
      conn
      |> reply(deployment)
    end
  end
end

defmodule LenraWeb.DeploymentsController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.Environment

  @impl Bouncer.Policy
  def authorize(:create, %User{id: user_id}, %Environment{creator_id: user_id}), do: true
  def authorize(:index, %User{id: user_id}, %Environment{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
