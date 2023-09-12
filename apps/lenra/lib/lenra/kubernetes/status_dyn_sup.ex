defmodule Lenra.Kubernetes.StatusDynSup do
  alias Lenra.Kubernetes.Status
  use DynamicSupervisor

  require Logger

  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    Logger.debug("#{__MODULE__} init")

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
end
