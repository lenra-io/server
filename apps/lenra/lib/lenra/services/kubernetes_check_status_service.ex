defmodule Lenra.KubernetesCheckStatusService do
  use GenServer

  alias Lenra.Apps
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def add_job(job_name, namespace, build_id) do
    GenServer.cast(__MODULE__, {:add_job, %{job_name: job_name, namespace: namespace, build_id: build_id}})
  end

  def init(_) do
    {:ok, %{jobs: [], current_index: 0}}
  end

  def handle_cast({:add_job, job}, %{jobs: []} = state) do
    Process.send_after(self(), :process_jobs, 5000)
    {:noreply, %{state | jobs: [job], current_index: 0}}
  end

  def handle_cast({:add_job, job}, state) do
    {:noreply, %{state | jobs: state.jobs ++ [job]}}
  end

  def handle_info(:process_jobs, state) do
    state = process_job(state)
    {:noreply, state}
  end

  defp process_job(%{jobs: [], current_index: _}) do
    %{jobs: [], current_index: 0}
  end

  defp process_job(%{jobs: jobs, current_index: index} = state) when index < length(jobs) do
    job = Enum.at(jobs, index)
    status = check_job_status(job)

    case status do
      :success ->
        update_build(job[:build_id], "success")
        # Remove the job from the queue
        %{state | jobs: List.delete_at(jobs, index)}

      :failure ->
        update_build(job[:build_id], "failure")
        # Remove the job from the queue
        %{state | jobs: List.delete_at(jobs, index)}

      _ ->
        # Move to the next job
        %{state | current_index: index + 1}
    end
  end

  defp process_job(state) do
    Process.send_after(self(), :process_jobs, 5000)
    %{state | current_index: 0}
  end

  defp check_job_status(job) do
    kubernetes_api_url = Application.fetch_env!(:lenra, :kubernetes_api_url)
    kubernetes_api_token = Application.fetch_env!(:lenra, :kubernetes_api_token)

    url = "#{kubernetes_api_url}/api/v1/namespaces/#{job[:namespace]}/pods/#{job[:job_name]}/status"
    headers = [{"Authorization", "Bearer #{kubernetes_api_token}"}]

    response =
      Finch.build(:get, url, headers)
      |> Finch.request(PipelineHttp)
      |> Stream.map(&Jason.decode!(&1.body))
      |> Stream.map(&extract_job_status(&1))
      |> Stream.run()

    case response do
      %{"succeeded" => 1} -> :success
      %{"failed" => 1} -> :failure
      _ -> :running
    end
  end

  defp extract_job_status(response) do
    # Extract the job status from the response
    response["status"]
  end

  defp maybe_deploy_in_main_env(build, "success"),
    do: Apps.deploy_in_main_env(build)

  defp maybe_deploy_in_main_env(build, "failure") do
    build.id
    |> Apps.get_deployement_for_build()
    |> Apps.update_deployement(%{status: :failure})

    {:ok, :not_deployed}
  end

  def update_build(build_id, status)
      when status in ["success", "failure"] do
    with {:ok, build} <- Apps.fetch_build(build_id),
         {:ok, _} <- Apps.update_build(build, %{status: status}) do
      maybe_deploy_in_main_env(build, status)
    end
  end

  def update_build(_build) do
    {:error, :invalid_build_status}
  end
end
