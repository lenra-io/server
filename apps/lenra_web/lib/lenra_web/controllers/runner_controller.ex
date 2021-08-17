defmodule LenraWeb.RunnerController do
  use LenraWeb, :controller
  require Logger

  alias Lenra.{BuildServices, DeploymentServices}

  def update_build(conn, %{"id" => build_id, "status" => status}) do
    with {:ok, build} <- BuildServices.fetch(build_id),
         {:ok, _} <- BuildServices.update(build, %{status: status}),
         {:ok, _} <- DeploymentServices.deploy_in_main_env(build) do
      conn
      |> reply
    end
  end
end
