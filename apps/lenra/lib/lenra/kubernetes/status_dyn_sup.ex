defmodule Lenra.Kubernetes.StatusDynSup do
  use DynamicSupervisor

  alias Lenra.Kubernetes.Status
  alias Lenra.Repo
  alias Lenra.Apps.Build

  import Ecto.Query

  require Logger

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: {:via, :swarm, __MODULE__})
  end

  @impl true
  def init(_init_arg) do
    Logger.debug("#{__MODULE__} init")

    init_status()

    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_build_status(build_id, namespace, job_name) do
    Logger.debug("#{__MODULE__} ensure query server started for #{inspect([build_id, namespace, job_name])}")

    case start_child(build_id, namespace, job_name) do
      {:ok, pid} ->
        Logger.info("Lenra.Kubernetes.Status started")
        Process.send_after(self(), :check, 10000)
        {:ok, pid}

      {:error, {:already_started, pid}} ->
        {:ok, pid}

      err ->
        Logger.critical(inspect(err))
        err
    end
  end

  defp start_child(build_id, namespace, job_name) do
    init_value = [
      build_id: build_id,
      namespace: namespace,
      job_name: job_name
    ]

    DynamicSupervisor.start_child(__MODULE__, {Status, init_value})
  end

  defp init_status() do
    kubernetes_build_namespace = Application.fetch_env!(:lenra, :kubernetes_build_namespace)

    builds =
      Repo.all(
        from(
          b in Build,
          where: b.status == "running"
        )
      )

    builds.each(fn build ->
      preloaded_build = Repo.preload(build, :application)

      build_name = "build-#{preloaded_build.application.service_name}-#{build.build_number}"

      start_build_status(build.id, kubernetes_build_namespace, build_name)
    end)
  end
end
