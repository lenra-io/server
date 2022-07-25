defmodule LenraWeb.DeploymentsController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.DeploymentsController.Policy

  alias Lenra.Apps

  def create(conn, %{"environment_id" => env_id, "build_id" => build_id} = params) do
    with user <- Guardian.Plug.current_resource(conn),
         {:ok, environment} <- Apps.fetch_env(env_id),
         :ok <- allow(conn, environment),
         {:ok, %{inserted_deployment: deployment}} <-
           Apps.create_deployment(env_id, build_id, user.id, params) do
      conn
      |> assign_data(deployment)
      |> reply
    end
  end
end

defmodule LenraWeb.DeploymentsController.Policy do
  alias Lenra.Accounts.User
  alias Lenra.Apps.Environment

  @impl Bouncer.Policy
  def authorize(:create, %User{id: user_id}, %Environment{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
