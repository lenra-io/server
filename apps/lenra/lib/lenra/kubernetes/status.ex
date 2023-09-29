defmodule Lenra.Kubernetes.Status do
  @moduledoc """
    Lenra.Kubernetes.Status check status for kubernetes build
  """
  use GenServer

  alias Lenra.Apps.Build
  alias LenraCommon.Errors.DevError
  alias LenraCommon.Errors.TechnicalError
  alias Lenra.{Apps, Repo}

  require Logger

  @check_delay 10_000

  def start_link(opts) do
    case Keyword.fetch(opts, :build_id) do
      {:ok, build_id} ->
        res = GenServer.start_link(__MODULE__, opts, name: {:global, {__MODULE__, build_id}})

        Logger.debug(
          "#{__MODULE__} start_link exit with #{inspect(res)} ans name #{inspect({:global, {__MODULE__, build_id}})}"
        )

        res

      :error ->
        raise DevError.exception(message: "Status need a build_id, a namespace and an job_name")
    end
  end

  def init(init_arg) do
    {:ok, build_id} = Keyword.fetch(init_arg, :build_id)
    {:ok, namespace} = Keyword.fetch(init_arg, :namespace)
    {:ok, job_name} = Keyword.fetch(init_arg, :job_name)

    {:ok, [build_id: build_id, namespace: namespace, job_name: job_name]}
  end

  def handle_call(:check, _from, state) do
    Process.send_after(self(), :check, @check_delay)
    {:reply, :ok, state}
  end

  def handle_info(:check, state) do
    case check_job_status(state) do
      :success -> check_and_update_build_status(state[:build_id], :success)
      :failure -> check_and_update_build_status(state[:build_id], :failure)
      :running -> Process.send_after(self(), :check, @check_delay)
    end

    {:noreply, state}
  end

  defp check_job_status(job) do
    Logger.debug("#{__MODULE__} Check job status for #{inspect(job)}")
    kubernetes_api_url = Application.fetch_env!(:lenra, :kubernetes_api_url)
    kubernetes_api_token = Application.fetch_env!(:lenra, :kubernetes_api_token)

    url = "#{kubernetes_api_url}/apis/batch/v1/namespaces/#{job[:namespace]}/jobs/#{job[:job_name]}/status"

    headers = [{"Authorization", "Bearer #{kubernetes_api_token}"}]

    Finch.build(:get, url, headers)
    |> Finch.request(PipelineHttp)
    |> response()
    |> case do
      {:ok, body} ->
        body
        |> extract_job_status
        |> case do
          %{"succeeded" => 1} ->
            Logger.debug("#{__MODULE__} Check job #{inspect(job)} success")
            :success

          %{"failed" => 1} ->
            Logger.debug("#{__MODULE__} Check job #{inspect(job)} failure")
            :failure

          _error ->
            Logger.debug("#{__MODULE__} Check job #{inspect(job)} frunning")
            :running
        end

      {:error, reason} ->
        Logger.debug("#{__MODULE__} Error while fetching job status")
        {:error, reason}
    end
  end

  defp extract_job_status(response) do
    # Extract the job status from the response
    response["status"]
  end

  defp check_and_update_build_status(build_id, status) do
    build = Repo.get(Build, build_id)

    if build.status == status do
      {:stop, :normal, [], nil}
    else
      update_build_status(build, status)
    end
  end

  defp update_build_status(build, status) do
    Logger.debug("#{__MODULE__} Update build status tp #{status}")

    case Apps.update_build(build, %{status: status}) do
      {:ok, _res} ->
        update_deployment(build)
        {:stop, :normal, [], nil}

      {:error, _reason} ->
        Logger.error("#{__MODULE__} Error while updating build status")
        {:stop, :normal, [], nil}
    end
  end

  def update_deployment(build) do
    build.id
    |> Apps.get_deployement_for_build()
    |> Apps.update_deployement(%{status: :failure})
  end

  defp response({:ok, %Finch.Response{status: 200, body: body}}) do
    {:ok, Jason.decode!(body)}
  end

  defp response({:ok, %Finch.Response{status: status_code, body: body}}) do
    case status_code do
      400 ->
        Logger.critical(TechnicalError.bad_request(body))
        TechnicalError.bad_request_tuple(body)

      404 ->
        Logger.error(TechnicalError.error_404(body))
        TechnicalError.error_404_tuple(body)

      500 ->
        Logger.critical(TechnicalError.bad_request(body))
        TechnicalError.error_500_tuple(body)

      504 ->
        Logger.critical(TechnicalError.error_500_tuple(body))
        TechnicalError.error_500_tuple(body)

      _err ->
        Logger.critical(TechnicalError.unknown_error(body))
        TechnicalError.unknown_error_tuple(body)
    end
  end

  def terminate(_reason, state) do
    # Perform cleanup operations here, if needed
    {:ok, state}
  end
end
