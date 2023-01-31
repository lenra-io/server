defmodule Lenra.OpenfaasServices do
  @moduledoc """
    The service that manage calls to an Openfaas action with `run_action/3`
  """

  alias Lenra.Apps
  alias Lenra.Errors.TechnicalError

  require Logger

  defp get_http_context do
    base_url = Application.fetch_env!(:lenra, :faas_url)
    auth = Application.fetch_env!(:lenra, :faas_auth)

    headers = [{"Authorization", auth}]
    {base_url, headers}
  end

  def get_function_name(service_name, build_number) do
    lenra_env = Application.fetch_env!(:lenra, :lenra_env)

    String.downcase("#{lenra_env}-#{service_name}-#{build_number}")
  end

  def deploy_app(service_name, build_number) do
    {base_url, headers} = get_http_context()

    url = "#{base_url}/system/functions"

    body =
      Jason.encode!(%{
        "image" => Apps.image_name(service_name, build_number),
        "service" => get_function_name(service_name, build_number),
        "secrets" => Application.fetch_env!(:lenra, :faas_secrets),
        "limits" => %{
          "memory" => "256Mi",
          "cpu" => "100m"
        },
        "requests" => %{
          "memory" => "128Mi",
          "cpu" => "50m"
        }
      })

    Logger.debug("Deploy Openfaas application \n#{url} : \n#{body}")

    Finch.build(
      :post,
      url,
      headers,
      body
    )
    |> Finch.request(FaasHttp, receive_timeout: 1000)
    |> response(:deploy_app)
  end

  def deploy?(service_name, build_number) do
    {base_url, headers} = get_http_context()

    url = "#{base_url}/system/functions/#{get_function_name(service_name, build_number)}"

    Finch.build(
      :get,
      url,
      headers
    )
    |> Finch.request(FaasHttp, receive_timeout: 1000)
    |> IO.inspect()
    |> response(:deploy_status)
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
    |> Finch.request(FaasHttp, receive_timeout: 1000)
    |> response(:delete_app)
  end

  defp response({:ok, %Finch.Response{status: status_code}}, :deploy_app)
       when status_code in [200, 202] do
    {:ok, status_code}
  end

  # defp response(
  #        {:ok, %Finch.Response{status: status_code, body: %{"availableReplicas" => availableReplicas}}},
  #        :deploy_status
  #      )
  #      when status_code in [200, 202] and availableReplicas != 0 do
  #   {:ok, :success}
  # end

  defp response(
         {:ok, %Finch.Response{status: status_code}},
         :deploy_status
       )
       when status_code in [200, 202] do
    false
  end

  defp response({:ok, %Finch.Response{status: status_code}}, :delete_app)
       when status_code in [200, 202] do
    {:ok, status_code}
  end

  defp response({:ok, %Finch.Response{body: body}}, :delete_app) do
    Logger.error("Openfaas could not delete the application. It should not happen. \n\t\t reason: #{body}")

    TechnicalError.openfaas_delete_error_tuple()
  end

  defp response({:error, %Mint.TransportError{reason: reason}}, _action) do
    Logger.error("Openfaas could not be reached. It should not happen. \n\t\t reason: #{reason}")
    TechnicalError.openfaas_not_reachable_tuple()
  end

  defp response(
         {:ok, %Finch.Response{status: status_code, body: body}},
         _action
       )
       when status_code not in [200, 202] do
    case status_code do
      400 ->
        Logger.error(body)
        TechnicalError.bad_request_tuple()

      404 ->
        Logger.error(body)
        :error404

      500 ->
        Logger.error(body)
        {:error, body}

      504 ->
        Logger.error(body)
        TechnicalError.timeout_tuple()

      _err ->
        Logger.error(body)
        TechnicalError.unknown_error_tuple()
    end
  end
end
