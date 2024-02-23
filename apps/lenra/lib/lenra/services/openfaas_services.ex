defmodule Lenra.OpenfaasServices do
  @moduledoc """
    The service that manage calls to an Openfaas function with `run_action/3`
  """

  alias ApplicationRunner.ApplicationServices
  alias Lenra.Apps
  alias Lenra.Subscriptions
  alias Lenra.Errors.TechnicalError
  alias LenraCommon.Errors

  require Logger

  @min_scale_label "com.openfaas.scale.min"
  @max_scale_label "com.openfaas.scale.max"
  @min_scale_default "1"

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

  def deploy_app(service_name, build_number, replicas) do
    ApplicationServices.deploy_app(
      get_function_name(service_name, build_number),
      Apps.image_name(service_name, build_number),
      replicas
    )
  end

  def is_deploy(service_name, build_number) do
    {base_url, headers} = get_http_context()

    url = "#{base_url}/system/function/#{get_function_name(service_name, build_number)}"

    Finch.build(
      :get,
      url,
      headers
    )
    |> Finch.request(FaasHttp, receive_timeout: 1000)
    |> response(:deploy_status)
  end

  def update_secrets(app, service_name, build_number, secrets \\ []) do
    {base_url, headers} = get_http_context()
    function_name = get_function_name(service_name, build_number)
    url = "#{base_url}/system/function/#{function_name}"

    body = Map.merge(ApplicationServices.generate_function_object(
      function_name,
      Apps.image_name(service_name, build_number),
      %{
        @min_scale_label => @min_scale_default,
        @max_scale_label => to_string(Subscriptions.get_max_replicas(app.id)),
        @scale_factor_label => @scale_factor_default
      }
    ), %{
      "secrets" => secrets
    }) |> Jason.encode!() |> IO.inspect(label: "OpenFaas Update Secret to")

    Finch.build(
      :put,
      url,
      headers,
      body
    )
    |> Finch.request(FaasHttp, receive_timeout: 1000) |> IO.inspect(label: "OpenFaas Response")
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

  defp response(
         {:ok, %Finch.Response{status: status_code, body: body}},
         :deploy_status
       )
       when status_code in [200, 202] do
    json_body = Jason.decode!(body)
    available_replicas = Map.get(json_body, "availableReplicas")
    available_replicas != 0 && available_replicas != nil
  end

  defp response({:ok, %Finch.Response{status: status_code}}, :delete_app)
       when status_code in [200, 202] do
    {:ok, status_code}
  end

  defp response({:ok, %Finch.Response{body: body}}, :delete_app) do
    Logger.error("Openfaas could not delete the application. It should not happen. \n\t\t reason: #{body}")

    TechnicalError.openfaas_delete_error_tuple()
  end

  defp response({:error, %Mint.TransportError{reason: reason}}, _function) do
    Logger.error("Openfaas could not be reached. It should not happen. \n\t\t reason: #{reason}")
    TechnicalError.openfaas_not_reachable_tuple()
  end

  defp response(
         {:ok, %Finch.Response{status: status_code, body: body}},
         _function
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
        body
        |> Errors.format_error_with_stacktrace()
        |> Logger.error()

        {:error, body}

      504 ->
        Logger.error(body)
        TechnicalError.timeout_tuple()

      _err ->
        body
        |> Errors.format_error_with_stacktrace()
        |> Logger.error()

        TechnicalError.unknown_error_tuple()
    end
  end
end
