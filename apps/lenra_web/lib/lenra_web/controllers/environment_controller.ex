defmodule LenraWeb.EnvsController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.EnvsController.Policy

  alias Lenra.Apps
  alias alias Lenra.Subscriptions
  alias Lenra.Subscriptions.Subscription

  defp get_app_and_allow(conn, %{"app_id" => app_id_str}) do
    with {app_id, _} <- Integer.parse(app_id_str),
         {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app) do
      {:ok, app}
    end
  end

  def index(conn, params) do
    with {:ok, app} <- get_app_and_allow(conn, params) do
      conn
      |> reply(Apps.all_envs_for_app(app.id))
    end
  end

  def create(conn, params) do
    with {:ok, app} <- get_app_and_allow(conn, params),
         user <- LenraWeb.Auth.current_resource(conn),
         {:ok, %{inserted_env: env}} <- Apps.create_env(app.id, user.id, params) do
      conn
      |> reply(env)
    end
  end

  def update(conn, %{"env_id" => env_id, "is_public" => true} = params) do
    with {:ok, app} <- get_app_and_allow(conn, params),
         {:ok, env} <- Apps.fetch_env(env_id),
         %Subscription{} = _subscription <- Subscriptions.get_subscription_by_app_id(app.id),
         {:ok, %{updated_env: env}} <- Apps.update_env(env, params) do
      conn
      |> reply(env)
    end
  end

  def update(conn, %{"env_id" => env_id} = params) do
    with {:ok, _app} <- get_app_and_allow(conn, params),
         {:ok, env} <- Apps.fetch_env(env_id),
         {:ok, %{updated_env: env}} <- Apps.update_env(env, params) do
      conn
      |> reply(env)
    end
  end
end

defmodule LenraWeb.EnvsController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.App
  alias Lenra.Subscriptions.Subscription

  @impl Bouncer.Policy
  def authorize(:index, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:create, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:update, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:update, %App{id: app_id}, %Subscription{application_id: app_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
