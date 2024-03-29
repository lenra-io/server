defmodule LenraWeb.EnvsController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.EnvsController.Policy

  alias Lenra.Apps
  alias Lenra.Errors.BusinessError
  alias alias Lenra.Subscriptions
  alias Lenra.Subscriptions.Subscription

  defp get_app_and_allow(conn, %{"app_id" => app_id_str}) do
    with {app_id, _} <- Integer.parse(app_id_str),
         {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app) do
      {:ok, app}
    end
  end

  defp get_app_env_and_allow(conn, %{"app_id" => app_id_str, "env_id" => env_id_str}) do
    with {app_id, _} <- Integer.parse(app_id_str),
         {env_id, _} <- Integer.parse(env_id_str),
         {:ok, env} <- Apps.fetch_app_env(app_id, env_id),
         app <- Map.get(env, :application),
         :ok <- allow(conn, %{app: app, env: env}) do
      {:ok, app, env}
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
    with {:ok, app, env} <- get_app_env_and_allow(conn, params),
         %Subscription{} = _subscription <- Subscriptions.get_subscription_by_app_id(app.id),
         {:ok, %{updated_env: env}} <- Apps.update_env(env, params) do
      conn
      |> reply(env)
    else
      nil -> BusinessError.subscription_required_tuple()
      error -> error
    end
  end

  def update(conn, %{"env_id" => env_id} = params) do
    with {:ok, _app, env} <- get_app_env_and_allow(conn, params),
         {:ok, %{updated_env: env}} <- Apps.update_env(env, params) do
      conn
      |> reply(env)
    end
  end
end

defmodule LenraWeb.EnvsController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.App
  alias Lenra.Apps.Environment
  alias Lenra.Subscriptions.Subscription

  @impl Bouncer.Policy
  def authorize(:index, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:create, %User{id: user_id}, %App{creator_id: user_id}), do: true

  def authorize(:update, %User{id: user_id}, %{
        app: %App{id: app_id, creator_id: user_id},
        env: %Environment{application_id: app_id}
      }),
      do: true

  def authorize(:update, %App{id: app_id}, %Subscription{application_id: app_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
