defmodule LenraWeb.ApplicationMainEnvController do
  use LenraWeb, :controller

  use LenraWeb.Policy,
    module: LenraWeb.ApplicationMainEnvController.Policy

  alias Lenra.{ApplicationMainEnvServices, EnvironmentServices, LenraApplicationServices}

  defp get_app_and_allow(conn, %{"app_id" => app_id_str}) do
    with {app_id, _} <- Integer.parse(app_id_str),
         {:ok, app} <- LenraApplicationServices.fetch(app_id),
         :ok <- allow(conn, app) do
      {:ok, app}
    end
  end

  def index(conn, params) do
    with {:ok, app} <- get_app_and_allow(conn, params) do
      conn
      |> assign_data(:main_env, ApplicationMainEnvServices.get(app.id))
      |> reply
    end
  end
end

defmodule LenraWeb.ApplicationMainEnvController.Policy do
  alias Lenra.{LenraApplication, User}

  @impl Bouncer.Policy
  def authorize(:index, %User{id: user_id}, %LenraApplication{creator_id: user_id}), do: true

  # credo:disable-for-next-line Credo.Check.Readability.StrictModuleLayout
  use LenraWeb.Policy.Default
end
