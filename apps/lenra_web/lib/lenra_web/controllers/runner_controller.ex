defmodule LenraWeb.RunnerController do
  use LenraWeb, :controller

  import Ecto.Query

  alias Lenra.Apps.Deployment
  alias Lenra.{Apps, Repo}
  require Logger

  defp maybe_deploy_in_main_env(build, "success"),
    do: Apps.deploy_in_main_env(build)

  defp maybe_deploy_in_main_env(build, "failure") do
    Repo.one(
      from(d in Deployment,
        select: d.build_id == ^build.id
      )
    )
    |> Apps.update_deployement(%{status: "failure"})

    {:ok, :not_deployed}
  end

  def update_build(conn, %{"id" => build_id, "status" => status})
      when status in ["success", "failure"] do
    with {:ok, build} <- Apps.fetch_build(build_id),
         {:ok, _} <- Apps.update_build(build, %{status: status}),
         {:ok, _} <- maybe_deploy_in_main_env(build, status) do
      reply(conn)
    end
  end

  def update_build(_conn, _params) do
    {:error, :invalid_build_status}
  end
end
