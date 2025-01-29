defmodule LenraWeb.UserEnvironmentRoleController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.UserEnvironmentRoleController.Policy

  alias Lenra.Apps
  alias Lenra.Apps.{Environment, UserEnvironmentAccess}
  alias Lenra.Errors.BusinessError
  alias Lenra.Repo
  alias LenraWeb.Auth

  defp get_access_and_allow(conn, %{
         "app_id" => app_id_str,
         "env_id" => env_id_str,
         "access_id" => access_id_str
       }) do
    with {app_id, _} <- Integer.parse(app_id_str),
         {env_id, _} <- Integer.parse(env_id_str),
         {access_id, _} <- Integer.parse(access_id_str),
         {:ok, access} <- fetch_access(app_id, env_id, access_id),
         :ok <- allow(conn, access) do
      {:ok, access}
    end
  end

  defp fetch_access(app_id, env_id, access_id) do
    UserEnvironmentAccess
    |> Repo.get_by(id: access_id, environment_id: env_id)
    |> Repo.preload(environment: [:application])
    |> case do
      # Check that the app id matches the app id in the environment
      %UserEnvironmentAccess{environment: %Environment{application_id: ^app_id}} = access -> {:ok, access}
      _error -> BusinessError.no_invitation_found_tuple()
    end
  end

  def index(conn, params) do
    with {:ok, access} <- get_access_and_allow(conn, params) do
      roles =
        access.id
        |> Apps.all_access_roles()
        |> Enum.map(fn role ->
          role.role
        end)

      conn
      |> reply(roles)
    end
  end

  def create(conn, %{"role" => role} = params) do
    with {:ok, access} <- get_access_and_allow(conn, params),
         user <- Auth.current_resource(conn),
         {:ok, %{inserted_user_role: user_env_role}} <-
           Apps.create_user_env_role(access.id, user.id, role) do
      conn
      |> reply(user_env_role)
    end
  end

  def delete(conn, %{"role" => role} = params) do
    with {:ok, access} <- get_access_and_allow(conn, params),
         {:ok, _} <-
           Apps.delete_user_env_role(access.id, role) do
      conn
      |> reply(%{})
    end
  end
end

defmodule LenraWeb.UserEnvironmentRoleController.Policy do
  alias ApplicationRunner.Contract.User
  alias Lenra.Accounts.User
  alias Lenra.Apps.App
  alias Lenra.Apps.Environment
  alias Lenra.Apps.UserEnvironmentAccess

  @impl Bouncer.Policy
  def authorize(:index, %User{id: user_id}, %UserEnvironmentAccess{
        environment: %Environment{application: %App{creator_id: user_id}}
      }),
      do: true

  def authorize(:create, %User{id: user_id}, %UserEnvironmentAccess{
        environment: %Environment{application: %App{creator_id: user_id}}
      }),
      do: true

  def authorize(:delete, %User{id: user_id}, %UserEnvironmentAccess{
        environment: %Environment{application: %App{creator_id: user_id}}
      }),
      do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
