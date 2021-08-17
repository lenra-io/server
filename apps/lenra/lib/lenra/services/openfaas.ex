defmodule Lenra.Openfaas do
  @moduledoc """
    The service that manage calls to an Openfaas action with `run_action/3`
  """
  require Logger

  alias Lenra.{Telemetry, DeploymentServices}
  alias ApplicationRunner.Action

  defp get_http_context do
    base_url = Application.fetch_env!(:lenra, :faas_url)
    auth = Application.fetch_env!(:lenra, :faas_auth)

    headers = [{"Authorization", auth}]
    {base_url, headers}
  end

  defp get_function_name(service_name, build_number) do
    lenra_env = Application.fetch_env!(:lenra, :lenra_env)
    "#{lenra_env}-#{service_name}-#{build_number}"
  end

  @doc """
    Run a HTTP POST request with needed headers and body to call an Openfaas Action and decode the response body.

    Returns `{:ok, decoded_body}` if the HTTP Post succeed
    Returns `{:error, reason}` if the HTTP Post fail
  """
  @spec run_action(Action.t()) :: {:ok, map}
  def run_action(action)
      when is_binary(action.app_name) and is_binary(action.action_name) and
             is_map(%{data: action.old_data, props: action.props, event: action.event}) do
    {base_url, headers} = get_http_context()
    function_name = get_function_name(action.app_name, action.build_number)

    url = "#{base_url}/function/#{function_name}"

    Logger.debug("Call to Openfaas : #{function_name}")

    headers = [{"Content-Type", "application/json"} | headers]
    params = Map.put(%{data: action.old_data, props: action.props, event: action.event}, :action, action.action_name)
    body = Jason.encode!(params)

    Logger.info("Run app #{action.app_name}[#{action.build_number}] with action #{action.action_name}")

    start_time = Telemetry.start(:openfaas_runaction)

    response =
      Finch.build(:post, url, headers, body)
      |> Finch.request(FaasHttp)
      |> response(:get_apps)

    docker_telemetry(response, action.action_logs_uuid)

    Telemetry.stop(:openfaas_runaction, start_time, %{
      user_id: action.user_id,
      uuid: action.action_logs_uuid
    })

    response
  end

  defp docker_telemetry({:ok, %{"stats" => %{"listeners" => listeners, "ui" => ui}}}, uuid) do
    Telemetry.event(:docker_run, %{uuid: uuid}, %{
      uiDuration: ui,
      listenersTime: listeners
    })
  end

  defp docker_telemetry(_response, _uuid) do
    # credo:disable-for-next-line
    # TODO: manage error case
  end

  @doc """
  Gets a resource from an app using a stream.

  Returns an `Enum`.
  """
  def get_app_resource(app_name, build_number, resource) do
    {base_url, headers} = get_http_context()
    function_name = get_function_name(app_name, build_number)

    url = "#{base_url}/function/#{function_name}"

    headers = [{"Content-Type", "application/json"} | headers]
    params = Map.put(%{}, :resource, resource)
    body = Jason.encode!(params)

    Finch.build(:post, url, headers, body)
    |> Finch.stream(FaasHttp, [], fn
      chunk, acc -> acc ++ [chunk]
    end)
  end

  def deploy_app(service_name, build_number) do
    {base_url, headers} = get_http_context()

    Logger.debug("Deploy Openfaas application")

    url = "#{base_url}/system/functions"

    Finch.build(
      :post,
      url,
      headers,
      Jason.encode!(%{
        "image" => DeploymentServices.image_name(service_name, build_number),
        "service" => get_function_name(service_name, build_number),
        "secrets" => Application.fetch_env!(:lenra, :faas_secrets)
      })
    )
    |> Finch.request(FaasHttp)
    |> response(:deploy_app)
  end

  def delete_app_openfaas(service_name, build_number) do
    {base_url, headers} = get_http_context()

    Logger.debug("Remove Openfaas application")

    url = "#{base_url}/system/functions"

    Finch.build(
      :delete,
      url,
      headers,
      Jason.encode!(%{
        "functionName" => get_function_name(service_name, build_number)
      })
    )
    |> Finch.request(FaasHttp)
    |> response(:delete_app)
  end

  defp response({:ok, %Finch.Response{status: 200, body: body}}, :get_apps) do
    {:ok, Jason.decode!(body)}
  end

  defp response({:ok, %Finch.Response{status: status_code}}, :deploy_app)
       when status_code in [200, 202] do
    {:ok, status_code}
  end

  defp response({:ok, %Finch.Response{status: status_code}}, :delete_app)
       when status_code in [200, 202, 404] do
    if status_code == 404 do
      Logger.error("The application was not found in Openfaas. It should not happen.")
    end

    {:ok, status_code}
  end

  defp response({:ok, %Finch.Response{}}, :delete_app) do
    raise "Openfaas could not delete the application. It should not happen."
  end

  defp response({:error, %Mint.TransportError{reason: _}}, _) do
    raise "Openfaas could not be reached. It should not happen."
  end

  defp response({:ok, %Finch.Response{status: status_code, body: body}}, _)
       when status_code not in [200, 202] do
    raise "Openfaas error (#{status_code}) #{body}"
  end
end
