defmodule LenraWeb.AppsController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.AppsController.Policy

  alias Lenra.Guardian.Plug
  alias Lenra.LenraApplicationServices

  require Logger

  def index(conn, _params) do
    with :ok <- allow(conn),
         user <- Plug.current_resource(conn),
         apps <- LenraApplicationServices.all(user.id) do
      conn
      |> assign_data(:apps, apps)
      |> reply
    end
  end

  def create(conn, params) do
    with :ok <- allow(conn),
         user <- Plug.current_resource(conn),
         {:ok, %{inserted_application: app}} <- LenraApplicationServices.create(user.id, params) do
      conn
      |> assign_data(:app, app)
      |> reply
    end
  end

  def update(conn, %{"id" => app_id} = params) do
    with {:ok, app} <- LenraApplicationServices.fetch(app_id),
         :ok <- allow(conn, app),
         {:ok, %{updated_application: app}} <- LenraApplicationServices.update(app, params) do
      conn
      |> assign_data(:updated_application, app)
      |> reply
    end
  end

  def delete(conn, %{"id" => app_id}) do
    with {:ok, app} <- LenraApplicationServices.fetch(app_id),
         :ok <- allow(conn, app),
         {:ok, _} <- LenraApplicationServices.delete(app) do
      reply(conn)
    end
  end

  def get_user_apps(conn, _params) do
    with :ok <- allow(conn),
         user <- Plug.current_resource(conn),
         apps <- LenraApplicationServices.all_for_user(user.id) do
      conn
      |> assign_data(:apps, apps)
      |> reply
    end
  end
end

defmodule LenraWeb.AppsController.Policy do
  alias Lenra.{LenraApplication, User}

  @impl Bouncer.Policy
  def authorize(:index, _user, _data), do: true
  def authorize(:create, %User{role: :dev}, _data), do: true
  def authorize(:delete, %User{id: user_id}, %LenraApplication{creator_id: user_id}), do: true
  def authorize(:get_user_apps, %User{role: :dev, id: user_id}, %LenraApplication{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
