defmodule LenraWeb.StripeController do
  alias Lenra.Subscriptions
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.AppsController.Policy

  alias Lenra.Apps
  alias LenraWeb.Auth

  require Logger

  def customer_create(conn, _params) do
    with user <- Auth.current_resource(conn),
         customer_id <- Subscriptions.create_customer_or_get_customer(user) do
      conn
      |> reply(customer_id)
    end
  end

  def index(conn, %{"id" => app_id} = params) do
    with {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app) do
      # Add get subscription
      conn
      |> reply(app)
    end
  end

  def checkout_create(conn, %{"id" => app_id} = params) do
    with {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app),
         :ok <- Subscriptions.create_checkout(params, app.id) do
      conn
      |> reply(app)
    end
  end
end

defmodule LenraWeb.StripeController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.App

  @impl Bouncer.Policy
  def authorize(:update, %User{id: user_id}, %App{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
