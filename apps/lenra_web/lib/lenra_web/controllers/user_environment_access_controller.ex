defmodule LenraWeb.UserEnvironmentAccessController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.UserEnvironmentAccessController.Policy

  alias Lenra.Apps
  alias Lenra.Subscriptions

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
    with {:ok, _app} <- get_app_and_allow(conn, params),
         subscription <- Subscriptions.get_subscription_by_app_id(env_id),
         {:ok, %{inserted_user_access: user_env_access}} <-
           Apps.create_user_env_access(env_id, %{"email" => email}, subscription) do
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
