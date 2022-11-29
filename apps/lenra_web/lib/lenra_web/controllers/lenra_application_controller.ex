defmodule LenraWeb.AppsController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.AppsController.Policy

  alias Lenra.Apps
  alias LenraWeb.Guardian.Plug

  require Logger

  def index(conn, _params) do
    with :ok <- allow(conn),
         user <- Plug.current_resource(conn),
         apps <- Apps.all_apps(user.id) do
      conn
      |> reply(apps)
    end
  end

  def create(conn, params) do
    with :ok <- allow(conn),
         user <- Plug.current_resource(conn),
         {:ok, %{inserted_application: app}} <- Apps.create_app(user.id, params) do
      conn
      |> reply(app)
    end
  end

  def update(conn, %{"id" => app_id} = params) do
    with {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app),
         {:ok, %{updated_application: app}} <- Apps.update_app(app, params) do
      conn
      |> reply(app)
    end
  end

  def delete(conn, %{"id" => app_id}) do
    with {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app),
         {:ok, _} <- Apps.delete_app(app) do
      reply(conn)
    end
  end

  def get_user_apps(conn, _params) do
    with :ok <- allow(conn),
         user <- Plug.current_resource(conn),
         apps <- Apps.all_apps_for_user(user.id) do
      conn
      |> reply(apps)
    end
  end

  def all_apps_user_opened(conn, _params) do
    with :ok <- allow(conn),
         user <- Plug.current_resource(conn),
         apps <- Apps.all_apps_user_opened(user.id) do
      reply(conn, apps)
    end
  end
end

defmodule LenraWeb.AppsController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.App

  @impl Bouncer.Policy
  def authorize(:index, _user, _data), do: true
  def authorize(:create, %User{role: :dev}, _data), do: true
  def authorize(:update, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:delete, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:get_user_apps, %User{role: :dev}, _data), do: true
  def authorize(:all_apps_user_opened, _user, _data), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
