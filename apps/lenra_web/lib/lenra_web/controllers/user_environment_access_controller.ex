defmodule LenraWeb.UserEnvironmentAccessController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.UserEnvironmentAccessController.Policy

  alias Lenra.Apps
  alias Lenra.Subscriptions

  defp get_app_env_and_allow(conn, %{"app_id" => app_id_str, "env_id" => env_id_str}) do
    with {app_id, _} <- Integer.parse(app_id_str),
         {env_id, _} <- Integer.parse(env_id_str),
         {:ok, env} <- Apps.fetch_app_env(app_id, env_id),
         app <- Map.get(env, :application),
         :ok <- allow(conn, %{app: app, env: env}) do
      {:ok, app, env}
    end
  end

  def index(conn, %{"env_id" => env_id} = params) do
    with {:ok, _app, _env} <- get_app_env_and_allow(conn, params) do
      access =
        env_id
        |> Apps.all_user_env_access_and_roles()
        |> Enum.map(fn access ->
          %{
            id: access.id,
            environment_id: access.environment_id,
            email: access.email,
            roles: access.roles |> Enum.map(& &1.role)
          }
        end)

      conn
      |> reply(access)
    end
  end

  def fetch_one(conn, %{"id" => id}) do
    with {:ok, invite} <- Apps.fetch_user_env_access(id: id) do
      conn
      |> reply(invite)
    end
  end

  def accept(conn, %{"id" => id}) do
    with user <- LenraWeb.Auth.current_resource(conn),
         {:ok, res} <- Apps.accept_invitation(id, user) do
      conn
      |> reply(res)
    end
  end

  def create(conn, %{"env_id" => env_id, "email" => email} = params) do
    with {:ok, _app, _env} <- get_app_env_and_allow(conn, params),
         subscription <- Subscriptions.get_subscription_by_app_id(env_id),
         {:ok, %{inserted_user_access: user_env_access}} <-
           Apps.create_user_env_access(env_id, %{"email" => email}, subscription) do
      conn
      |> reply(user_env_access)
    end
  end

  def delete(conn, %{"env_id" => env_id, "email" => email} = params) do
    with {:ok, _app, _env} <- get_app_env_and_allow(conn, params),
         {1, _} <-
           Apps.delete_user_env_access(%{environment_id: env_id, email: email}) do
      conn
      |> reply(%{})
    end
  end
end

defmodule LenraWeb.UserEnvironmentAccessController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.App
  alias Lenra.Apps.Environment

  @impl Bouncer.Policy
  def authorize(:index, %User{id: user_id}, %{
        app: %App{id: app_id, creator_id: user_id},
        env: %Environment{application_id: app_id}
      }),
      do: true

  def authorize(:create, %User{id: user_id}, %{
        app: %App{id: app_id, creator_id: user_id},
        env: %Environment{application_id: app_id}
      }),
      do: true

  def authorize(:delete, %User{id: user_id}, %{
        app: %App{id: app_id, creator_id: user_id},
        env: %Environment{application_id: app_id}
      }),
      do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
