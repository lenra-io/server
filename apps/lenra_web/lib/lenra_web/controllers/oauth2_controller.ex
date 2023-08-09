defmodule LenraWeb.OAuth2Controller do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.OAuth2Controller.Policy

  alias Lenra.Apps

  require Logger

  def index(conn, %{"environment_id" => env_id} = params) do
    with :ok <- allow_creator_only(conn, params),
         {:ok, clients} <- Apps.get_oauth2_clients(env_id) do
      conn
      |> reply(clients)
    end
  end

  def create(conn, params) do
    with :ok <- allow_creator_only(conn, params),
         {:ok, clients} <- Apps.create_oauth2_client(params) do
      conn
      |> reply(clients)
    end
  end

  def update(conn, params) do
    with :ok <- allow_creator_only(conn, params),
         {:ok, updated} <- Apps.update_oauth2_client(params) do
      conn
      |> reply(updated)
    end
  end

  def delete(conn, params) do
    with :ok <- allow_creator_only(conn, params),
         {:ok, deleted} <- Apps.delete_oauth2_client(params) do
      conn
      |> reply(deleted |> Map.take([:oauth2_client_id, :environment_id]))
    end
  end

  defp allow_creator_only(conn, %{"environment_id" => env_id}) do
    with {:ok, app} <- Apps.fetch_app_for_env(env_id) do
      allow(conn, app)
    end
  end
end

defmodule LenraWeb.OAuth2Controller.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.App

  @impl Bouncer.Policy
  # Whatever the action, you must be the app creator to manage the oauth client
  def authorize(_action, %User{id: user_id}, %App{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
