defmodule LenraWeb.EnvsController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.EnvsController.Policy

  alias Lenra.{Apps, Repo}
  alias Lenra.Apps.{Environment}
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

  def list_secrets(conn, %{"env_id" => env_id} = params) do
    with {:ok, _app} <- get_app_and_allow(conn, params),
         {:ok, environment} <- Apps.fetch_env(env_id),
         env_secrets <- Apps.all_env_secrets_for_env(environment.id) do
      conn
      |> reply(env_secrets)
    end
  end

  def create_secret(conn, %{"env_id" => env_id, "key" => key} = params) do
    with {:ok, _app} <- get_app_and_allow(conn, params),
         {:ok, environment} <- Apps.fetch_env(env_id),
         {:ok, %{inserted_env_secret: env_secret}} <- Apps.create_env_secret(environment.id, key, params) do
      conn
      |> reply(env_secret)
    end
  end

  # def update_secret(conn, %{"env_id" => env_id, "key" => key} = params) do
  #   with {:ok, _app} <- get_app_and_allow(conn, params),
  #        {:ok, environment} <- Apps.fetch_env(env_id),
  #        {:ok, secret} <- Repo.update_all(from(s in EnvSecret,
  #           where: s.environment_id == environment.id and s.key == key ),
  #           order_by: is_nil(s.environment_id),
  #           limit: 1
  #         ),
  #        {:ok, %{updated_env_secret: env_secret}} <- Apps.update_env_secret(secret, params) do
  #     conn
  #     |> reply(env_secret)
  #   end
  # end

  def delete_secret(conn, %{"env_id" => env_id, "key" => key} = params) do
    with {:ok, _app} <- get_app_and_allow(conn, params),
         {:ok, environment} <- Apps.fetch_env(env_id),
         {:ok, %{deleted_env_secret: env_secret}} <- Apps.delete_env_secret(environment.id, key) do
      conn
      |> reply(env_secret)
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

  def authorize(:list_secrets, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:create_secret, %User{id: user_id}, %App{creator_id: user_id}), do: true
  # def authorize(:update_secret, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:delete_secret, %User{id: user_id}, %App{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
