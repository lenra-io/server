defmodule Lenra.Kubernetes.Status do
  use GenServer
  use SwarmNamed

  alias LenraCommon.Errors.TechnicalError
  alias LenraCommon.Errors.DevError
  alias Lenra.{Apps, Repo}

  require Logger

  @check_delay 10000

  def start_link(opts) do
    with {:ok, build_id} <- Keyword.fetch(opts, :build_id) do
      GenServer.start_link(__MODULE__, opts, name: get_full_name({build_id}))
    else
      :error ->
        raise DevError.exception(message: "Status need a build_id, a namespace and an job_name")

      {:error, reason} ->
        {:error, reason}
    end
  end

  def init(init_arg) do
    {:ok, build_id} = Keyword.fetch(init_arg, :build_id)
    {:ok, namespace} = Keyword.fetch(init_arg, :namespace)
    {:ok, job_name} = Keyword.fetch(init_arg, :job_name)

    {:ok, {build_id, namespace, job_name}}
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
    kubernetes_api_url = Application.fetch_env!(:lenra, :kubernetes_api_url)
    kubernetes_api_token = Application.fetch_env!(:lenra, :kubernetes_api_token)

    url = "#{kubernetes_api_url}/api/v1/namespaces/#{job[:namespace]}/pods/#{job[:job_name]}/status"

    headers = [{"Authorization", "Bearer #{kubernetes_api_token}"}]

    Finch.build(:get, url, headers)
    |> Finch.request(PipelineHttp)
    |> response()
    |> case do
      {:ok, body} ->
        body
        |> extract_job_status
        |> case do
          %{"succeeded" => 1} -> :success
          %{"failed" => 1} -> :failure
          _ -> :running
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
