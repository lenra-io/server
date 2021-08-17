defmodule LenraWeb.AppsController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.AppsController.Policy

  require(Logger)

  alias Lenra.LenraApplicationServices
  alias Lenra.Guardian.Plug

  def index(conn, _params) do
    with :ok <- allow(conn),
         apps <- LenraApplicationServices.all() do
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

  def delete(conn, %{"name" => app_name}) do
    with {:ok, app} <- LenraApplicationServices.fetch_by(name: app_name),
         :ok <- allow(conn, app),
         {:ok, _} <- LenraApplicationServices.delete(app) do
      reply(conn)
    end
  end

  def get_user_apps(conn, _params) do
    with :ok <- allow(conn),
         user <- Plug.current_resource(conn),
         apps <- LenraApplicationServices.all(user.id) do
      conn
      |> assign_data(:apps, apps)
      |> reply
    end
  end
end

defmodule LenraWeb.AppsController.Policy do
  alias Lenra.{User, LenraApplication}

  @impl Bouncer.Policy
  def authorize(:index, _, _), do: true
  def authorize(:create, %User{role: :dev}, _), do: true
  def authorize(:delete, %User{id: user_id}, %LenraApplication{creator_id: user_id}), do: true
  def authorize(:get_user_apps, %User{role: :dev}, _), do: true

  use LenraWeb.Policy.Default
end
