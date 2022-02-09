defmodule LenraWeb.RunnerController do
  use LenraWeb, :controller
  alias Lenra.{BuildServices, DeploymentServices}
  require Logger

  defp maybe_deploy_in_main_env(build, "success"),
    do: DeploymentServices.deploy_in_main_env(build)

  defp maybe_deploy_in_main_env(_build, "failure"), do: {:ok, :not_deployed}

  def update_build(conn, %{"id" => build_id, "status" => status})
      when status in ["success", "failure"] do
    with {:ok, build} <- BuildServices.fetch(build_id),
         {:ok, _} <- BuildServices.update(build, %{status: status}),
         {:ok, _} <- maybe_deploy_in_main_env(build, status) do
      reply(conn)
    end
  end

  def update_build(_conn, _params) do
    {:error, :invalid_build_status}
  end
end
