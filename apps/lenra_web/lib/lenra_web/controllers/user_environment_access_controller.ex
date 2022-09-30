defmodule LenraWeb.UserEnvironmentAccessController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.UserEnvironmentAccessController.Policy

  alias Lenra.Apps

  defp get_app_and_allow(conn, %{"app_id" => app_id_str}) do
    with {app_id, _} <- Integer.parse(app_id_str),
         {:ok, app} <- Apps.fetch_app(app_id),
         :ok <- allow(conn, app) do
      {:ok, app}
    end
  end

  def index(conn, %{"env_id" => env_id} = params) do
    with {:ok, _app} <- get_app_and_allow(conn, params) do
      conn
      |> reply(Apps.all_user_env_access(env_id))
    end
  end

  def fetch_one(conn, %{"uuid" => uuid}) do
    with {:ok, invite} <- Apps.fetch_user_env_access(uuid: uuid) do
      conn
      |> reply(invite)
    end
  end

  def accept(conn, %{"uuid" => uuid}) do
    with user <- Guardian.Plug.current_resource(conn),
         app_name <- Apps.accept_invite(uuid, user) do
      conn
      |> reply(%{app_name: app_name})
    end
  end

  def create(conn, %{"env_id" => env_id, "email" => email} = params) do
    with {:ok, _app} <- get_app_and_allow(conn, params),
         {:ok, %{inserted_user_access: user_env_access}} <-
           Apps.create_user_env_access(env_id, %{"email" => email}) do
      conn
      |> reply(user_env_access)
    end
  end
end

defmodule LenraWeb.UserEnvironmentAccessController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.App

  @impl Bouncer.Policy
  def authorize(:index, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:create, %User{id: user_id}, %App{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
