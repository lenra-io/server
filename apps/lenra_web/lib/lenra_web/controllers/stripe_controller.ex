defmodule LenraWeb.StripeController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.StripeController.Policy

  alias Lenra.Apps
  alias LenraWeb.Auth
  alias Lenra.Subscriptions

  require Logger

  def customer_create(conn, _params) do
    with user <- Auth.current_resource(conn),
         customer_id <- Subscriptions.create_customer_or_get_customer(user) do
      conn
      |> reply(customer_id)
    end
  end

  def index(conn, %{"id" => app_id}) do
    with {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app),
         subscription <- Subscriptions.get_subscription_by_app_id(app.id) do
      # Add get subscription
      conn
      |> reply(subscription)
    end
  end

  def checkout_create(conn, %{"id" => app_id} = params) do
    with {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app),
         session_id <- Subscriptions.create_checkout(params, app.id) do
      conn
      |> reply(session_id)
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
