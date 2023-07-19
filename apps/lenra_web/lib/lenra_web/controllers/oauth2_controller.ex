defmodule LenraWeb.AppsController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.AppsController.Policy

  alias Lenra.Apps
  alias LenraWeb.Auth

  require Logger

  def create(conn, params) do
    with :ok <- allow(conn),
         user <- Auth.current_resource(conn),
         {:ok, %{inserted_application: app}} <- Apps.create_app(user.id, params) do
      conn
      |> reply(app)
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
