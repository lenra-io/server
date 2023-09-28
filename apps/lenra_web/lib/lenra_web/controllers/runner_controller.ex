defmodule LenraWeb.RunnerController do
  use LenraWeb, :controller

  alias Lenra.{Apps, Kubernetes}
  require Logger

  defp maybe_deploy_in_main_env(build, "success"),
    do: Apps.deploy_in_main_env(build)

  defp maybe_deploy_in_main_env(build, "failure") do
    build.id
    |> Apps.get_deployement_for_build()
    |> Apps.update_deployement(%{status: :failure})

    {:ok, :not_deployed}
  end

  def update_build(conn, %{"id" => build_id, "status" => status})
      when status in ["success", "failure"] do
    with {:ok, build} <- Apps.fetch_build(build_id),
         {:ok, _} <- Apps.update_build(build, %{status: status}),
         {:ok, _} <- maybe_deploy_in_main_env(build, status) do
      if String.downcase(Application.fetch_env!(:lenra, :pipeline_runner)) == "kubernetes" do
        GenServer.stop({:global, {Kubernetes.Status, build_id}})
      end

      reply(conn)
    end
  end

  def update_build(_conn, _params) do
    {:error, :invalid_build_status}
  end
end
