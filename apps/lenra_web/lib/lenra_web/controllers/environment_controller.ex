defmodule LenraWeb.EnvsController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.EnvsController.Policy

  alias Lenra.Apps

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
      |> assign_data(Apps.all_envs_for_app(app.id))
      |> reply
    end
  end

  def create(conn, params) do
    with {:ok, app} <- get_app_and_allow(conn, params),
         user <- Guardian.Plug.current_resource(conn),
         {:ok, %{inserted_env: env}} <- Apps.create_env(app.id, user.id, params) do
      conn
      |> assign_data(env)
      |> reply
    end
  end

  def update(conn, %{"env_id" => env_id} = params) do
    with {:ok, _app} <- get_app_and_allow(conn, params),
         {:ok, env} <- Apps.fetch_env(env_id),
         {:ok, %{updated_env: env}} <- Apps.update_env(env, params) do
      conn
      |> assign_data(env)
      |> reply
    end
  end
end

defmodule LenraWeb.EnvsController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.App

  @impl Bouncer.Policy
  def authorize(:index, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:create, %User{id: user_id}, %App{creator_id: user_id}), do: true
  def authorize(:update, %User{id: user_id}, %App{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
