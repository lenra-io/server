defmodule Lenra.OpenfaasServices do
  @moduledoc """
    The service that manage calls to an Openfaas action with `run_action/3`
  """
  alias Lenra.{DeploymentServices, Environment, LenraApplication}
  require Logger

  defp get_http_context do
    base_url = Application.fetch_env!(:lenra, :faas_url)
    auth = Application.fetch_env!(:lenra, :faas_auth)

    headers = [{"Authorization", auth}]
    {base_url, headers}
  end

  defp get_function_name(service_name, build_number) do
    lenra_env = Application.fetch_env!(:lenra, :lenra_env)

    String.downcase("#{lenra_env}-#{service_name}-#{build_number}")
  end

  @doc """
    Run a HTTP POST request with needed headers and body to call an Openfaas Action and decode the response body.

    Returns `{:ok, decoded_body}` if the HTTP Post succeed
    Returns `{:error, reason}` if the HTTP Post fail
  """
  @spec run_listener(LenraApplication.t(), Environment.t(), String.t(), map(), map(), map()) ::
          {:ok, map()} | {:error, any()}
  def run_listener(
        %LenraApplication{} = application,
        %Environment{} = environment,
        action,
        data,
        props,
        event
      ) do
    {base_url, base_headers} = get_http_context()

    function_name = get_function_name(application.service_name, environment.deployed_build.build_number)

    url = "#{base_url}/function/#{function_name}"

    headers = [{"Content-Type", "application/json"} | base_headers]
    body = Jason.encode!(%{action: action, data: data, props: props, event: event})

    Logger.debug("Call to Openfaas : #{function_name}")

    Logger.debug(
      "Run app #{application.service_name}[#{environment.deployed_build.build_number}] with action #{action}"
    )

    Finch.build(:post, url, headers, body)
    |> Finch.request(FaasHttp)
    |> response(:decode)
    |> case do
      {:ok, %{"data" => data}} -> {:ok, data}
      err -> err
    end
  end

  @spec fetch_widget(LenraApplication.t(), Environment.t(), String.t(), map(), map()) ::
          {:ok, map()} | {:error, any()}
  def fetch_widget(
        %LenraApplication{} = application,
        %Environment{} = environment,
        widget_name,
        data,
        props
      ) do
    {base_url, base_headers} = get_http_context()

    function_name = get_function_name(application.service_name, environment.deployed_build.build_number)

    url = "#{base_url}/function/#{function_name}"
    headers = [{"Content-Type", "application/json"} | base_headers]
    body = Jason.encode!(%{widget: widget_name, data: data, props: props})

    Finch.build(:post, url, headers, body)
    |> Finch.request(FaasHttp)
    |> response(:decode)
    |> case do
      {:ok, %{"widget" => widget}} -> {:ok, widget}
      err -> err
    end
  end

  @spec fetch_manifest(LenraApplication.t(), Environment.t()) :: {:ok, map()} | {:error, any()}
  def fetch_manifest(%LenraApplication{} = application, %Environment{} = environment) do
    {base_url, base_headers} = get_http_context()

    function_name = get_function_name(application.service_name, environment.deployed_build.build_number)

    url = "#{base_url}/function/#{function_name}"
    headers = [{"Content-Type", "application/json"} | base_headers]

    Finch.build(:post, url, headers)
    |> Finch.request(FaasHttp)
    |> response(:decode)
    |> case do
      {:ok, %{"manifest" => manifest}} ->
        Logger.debug("Got manifest : #{inspect(manifest)}")
        {:ok, manifest}

      err ->
        Logger.error("Error while getting manifest : #{inspect(err)}")
        err
    end
  end

  @doc """
  Gets a resource from an app using a stream.

  Returns an `Enum`.
  """
  def get_app_resource(app_name, build_number, resource) do
    {base_url, base_headers} = get_http_context()
    function_name = get_function_name(app_name, build_number)

    url = "#{base_url}/function/#{function_name}"

    headers = [{"Content-Type", "application/json"} | base_headers]
    params = Map.put(%{}, :resource, resource)
    body = Jason.encode!(params)

    Finch.build(:post, url, headers, body)
    |> Finch.stream(FaasHttp, [], fn
      chunk, acc -> acc ++ [chunk]
    end)
  end

  def deploy_app(service_name, build_number) do
    {base_url, headers} = get_http_context()

    url = "#{base_url}/system/functions"

    body =
      Jason.encode!(%{
        "image" => DeploymentServices.image_name(service_name, build_number),
        "service" => get_function_name(service_name, build_number),
        "secrets" => Application.fetch_env!(:lenra, :faas_secrets)
      })

    Logger.debug("Deploy Openfaas application \n#{url} : \n#{body}")

    Finch.build(
      :post,
      url,
      headers,
      body
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

  defp response({:ok, %Finch.Response{status: 200, body: body}}, :decode) do
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

  defp response({:error, %Mint.TransportError{reason: _reason}}, _action) do
    raise "Openfaas could not be reached. It should not happen."
  end

  defp response({:ok, %Finch.Response{status: status_code, body: body}}, _action)
       when status_code not in [200, 202] do
    raise "Openfaas error (#{status_code}) #{body}"
  end
end
