defmodule LenraWeb.RunnerController do
  use LenraWeb, :controller
  require Logger

  alias Lenra.{BuildServices, DeploymentServices}

  def update_build(conn, %{"id" => build_id, "status" => status}) when status == "success" do
    with {:ok, build} <- BuildServices.fetch(build_id),
         {:ok, _} <- BuildServices.update(build, %{status: status}),
         {:ok, _} <- DeploymentServices.deploy_in_main_env(build) do
      conn
      |> reply
    end
  end

  def update_build(conn, %{"id" => build_id, "status" => status}) when status == "failure" do
    with {:ok, build} <- BuildServices.fetch(build_id),
         {:ok, _} <- BuildServices.update(build, %{status: status}) do
      conn
      |> put_status(:bad_request)
      |> add_error(:build_fail)
      |> reply
    end
  end
end
