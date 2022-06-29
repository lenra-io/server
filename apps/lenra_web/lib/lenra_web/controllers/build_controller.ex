defmodule LenraWeb.BuildsController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.BuildsController.Policy

  alias Lenra.Apps

  def index(conn, %{"app_id" => app_id}) do
    with {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app) do
      conn
      |> assign_data(:builds, Apps.all_builds(app.id))
      |> reply
    end
  end

  def create(conn, %{"app_id" => app_id_str} = params) do
    with {app_id, _} <- Integer.parse(app_id_str),
         user <- Guardian.Plug.current_resource(conn),
         {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app),
         {:ok, %{inserted_build: build}} <-
           Apps.create_build_and_trigger_pipeline(user.id, app.id, params) do
      conn
      |> assign_data(build)
      |> reply
    end
  end
end

defmodule LenraWeb.BuildsController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.{App, Build}

  @impl Bouncer.Policy
  def authorize(:index, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:create, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:update, %User{id: user_id}, %Build{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
