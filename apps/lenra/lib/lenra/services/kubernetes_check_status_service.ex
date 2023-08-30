defmodule Lenra.Services.KubernetesCheckStatusService do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init([]) do
    {:ok, %{pods_to_check: [], timer_ref: nil}}
  end

  def handle_call({:get_pods_to_check}, _from, state) do
    {:reply, state[:pods_to_check], state}
  end

  def handle_call({:get_timer_ref}, _from, state) do
    {:reply, state[:timer_ref], state}
  end

  def handle_call({:clear_pods_to_check}, _from, state) do
    {:reply, :ok, %{state | pods_to_check: []}}
  end

  def handle_call({:add_pods_to_check, pod_name, namespace, build_id}, _from, state) do
    new_pods_to_check = state[:pods_to_check] ++ {:running, pod_name, namespace, build_id}
    if new_pods_to_check == [] do
      {:reply, :ok, %{state | pods_to_check: new_pods_to_check, timer_ref: nil}}
    else
      {:reply, :ok, %{state | pods_to_check: new_pods_to_check}}
    end
  end

  def handle_info(:check_pods_status, state) do
    case state[:pods_to_check] do
      [] ->
        {:noreply, %{state | timer_ref: nil}}
      pods ->
        {pod, remaining_pods} = List.pop(pods)
        case get_pod_status(pod[:pod_name], pod[:namespace], pod[:build_id]) do
          {:ok, "success"} ->
            update_build_status(pod[:build_id], "succeeded")
            {:noreply, %{state | pods_to_check: remaining_pods}}
          {:ok, "failure"} ->
            update_build_status(pod[:build_id], "failed")
            {:noreply, %{state | pods_to_check: remaining_pods}}
          {:ok, _} ->
            Process.send_after(self(), :check_pods_status, 5000)
            {:noreply, %{state | pods_to_check: remaining_pods}}
          {:error, _reason} ->
            update_build_status(pod[:build_id], "failed")
            {:noreply, %{state | pods_to_check: remaining_pods}}
        end
    end
  end

  defp get_pod_status(pod_name, namespace, build_id) do
    kubernetes_api_url = Application.fetch_env!(:lenra, :kubernetes_api_url)
    kubernetes_api_token = Application.fetch_env!(:lenra, :kubernetes_api_token)

    url = "#{kubernetes_api_url}/api/v1/namespaces/#{namespace}/pods/#{pod_name}/status"
    headers = [{"Authorization", "Bearer #{kubernetes_api_token}"}]

    Finch.build(:get, url, headers)
    |> Finch.request(PipelineHttp)
    |> Stream.map(&Jason.decode!(&1.body))
    |> Stream.map(&extract_pod_status(&1))
    |> Stream.map(&update_build_status(&1, build_id))
    |> Stream.run()
  end

  defp extract_pod_status(%{"phase" => phase, "containerStatuses" => container_statuses, "initContainerStatuses" => init_container_statuses}) do
    %{
      phase: phase,
      container_statuses: container_statuses |> Enum.map(&extract_container_status/1),
      init_container_statuses: init_container_statuses |> Enum.map(&extract_container_status/1)
    }
  end

  defp extract_container_status(%{"name" => name, "state" => state}) do
    case state do
      %{"running" => info} ->
        %{
          name: name,
          state: "running"
        }
      %{"terminated" => %{"reason" => reason}} ->
        %{
          name: name,
          state: reason
        }
      %{"waiting" => %{"reason" => reason}} ->
        %{
          name: name,
          state: reason
        }
    end
  end

  defp update_build_status(build_id, status) do
    # Update build status to "succeeded" or "failed"
    # ...
  end
end
