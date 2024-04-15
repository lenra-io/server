defmodule ApplicationRunner.ApplicationServices do
  @moduledoc """
    The service that manages calls to an Openfaas function with `run_action/3`
  """
  alias ApplicationRunner.Errors.TechnicalError
  alias ApplicationRunner.Guardian.AppGuardian
  alias ApplicationRunner.Telemetry
  alias LenraCommon.Errors

  require Logger

  @empty_body "{}"
  @empty_body_length "2"
  @min_scale_label "com.openfaas.scale.min"
  @max_scale_label "com.openfaas.scale.max"
  @scale_factor_label "com.openfaas.scale.factor"
  @min_scale_default "1"
  @max_scale_default "5"
  @scale_factor_default "10"

  defp get_http_context do
    base_url = Application.fetch_env!(:application_runner, :faas_url)
    auth = Application.fetch_env!(:application_runner, :faas_auth)

    headers = [{"Authorization", auth}]
    Logger.debug("Get http context: #{inspect({base_url, headers})}")
    {base_url, headers}
  end

  @doc """
    Run a HTTP POST request with needed headers and body to call an Openfaas function and decode the response body.

    Returns `:ok` if the HTTP Post succeed
    Returns `{:error, reason}` if the HTTP Post fail
  """
  @spec run_listener(String.t(), String.t(), map(), map(), String.t()) ::
          :ok | {:error, any()}
  def run_listener(
        function_name,
        listener,
        props,
        event,
        token
      ) do
    {base_url, base_headers} = get_http_context()

    url = "#{base_url}/function/#{function_name}"

    body =
      Jason.encode!(%{
        listener: listener,
        props: props,
        event: event,
        api: %{url: Application.fetch_env!(:application_runner, :internal_api_url), token: token}
      })

    headers = [
      {"Content-Type", "application/json"},
      {"Content-length", to_string(byte_size(body))} | base_headers
    ]

    Logger.debug("Call to Openfaas : #{function_name}")

    Logger.debug("Run app #{function_name} with listener #{listener}")

    peeked_token = AppGuardian.peek(token)
    start_time = Telemetry.start(:app_listener, peeked_token.claims)

    res =
      Finch.build(:post, url, headers, body)
      |> Finch.request(AppHttp,
        receive_timeout: Application.fetch_env!(:application_runner, :listeners_timeout)
      )
      |> response(:listener)

    Logger.debug("response: #{inspect(res)}")
    Telemetry.stop(:app_listener, start_time, peeked_token.claims)

    res
  end

  @spec fetch_view(String.t(), String.t(), map(), map(), map()) ::
          {:ok, map()} | {:error, any()}
  def fetch_view(
        function_name,
        view_name,
        data,
        props,
        context
      ) do
    {base_url, base_headers} = get_http_context()

    url = "#{base_url}/function/#{function_name}"
    body = Jason.encode!(%{view: view_name, data: data, props: props, context: context})

    headers = [
      {"Content-Type", "application/json"},
      {"Content-length", to_string(byte_size(body))} | base_headers
    ]

    Logger.debug("Fetch application view \n#{url} : \n#{body}")

    Finch.build(:post, url, headers, body)
    |> Finch.request(AppHttp,
      receive_timeout: Application.fetch_env!(:application_runner, :view_timeout)
    )
    |> response(:view)
    |> case do
      {:ok, %{"view" => view}} ->
        Logger.debug("Got view #{inspect(view)}")

        {:ok, view}

      err ->
        err
    end
  end

  @spec fetch_manifest(String.t()) :: {:ok, map()} | {:error, any()}
  def fetch_manifest(function_name) do
    {base_url, base_headers} = get_http_context()

    url = "#{base_url}/function/#{function_name}"

    headers = [
      {"Content-Type", "application/json"},
      {"Content-length", @empty_body_length} | base_headers
    ]

    Logger.debug("Fetch application manifest \n#{url} : \n#{function_name}")

    Finch.build(:post, url, headers, @empty_body)
    |> Finch.request(AppHttp,
      receive_timeout: Application.fetch_env!(:application_runner, :manifest_timeout)
    )
    |> response(:manifest)
    |> case do
      {:ok, manifest} ->
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
  @spec get_app_resource_stream(String.t(), String.t()) :: {:ok, term()} | {:error, Exception.t()}
  def get_app_resource_stream(function_name, resource) do
    {base_url, base_headers} = get_http_context()

    url = "#{base_url}/function/#{function_name}"

    body = Jason.encode!(%{resource: resource})

    headers = [
      {"Content-Type", "application/json"},
      {"Content-length", to_string(byte_size(body))} | base_headers
    ]

    Finch.build(:post, url, headers, body)
    |> Finch.stream(AppHttp, [], fn
      chunk, acc -> acc ++ [chunk]
    end)
    |> response(:resource)
  end

  @spec generate_function_object(String.t(), String.t(), map()) :: map()
  def generate_function_object(function_name, image_name, labels) do
    %{
      "image" => image_name,
      "service" => function_name,
      "secrets" => Application.fetch_env!(:application_runner, :faas_secrets),
      "requests" => %{
        "cpu" => Application.fetch_env!(:application_runner, :faas_request_cpu),
        "memory" => Application.fetch_env!(:application_runner, :faas_request_memory)
      },
      "limits" => %{
        "cpu" => Application.fetch_env!(:application_runner, :faas_limit_cpu),
        "memory" => Application.fetch_env!(:application_runner, :faas_limit_memory)
      },
      "labels" => labels
    }
  end

  @doc """
  Deploy an application to OpenFaaS.
  """
  @spec deploy_app(String.t(), String.t(), integer()) :: :ok | {:error, struct} | {:ok, any}
  def deploy_app(function_name, image_name, replicas) do
    Logger.info("Deploy Openfaas application #{function_name} with image #{image_name}")

    {base_url, headers} = get_http_context()

    url = "#{base_url}/system/functions"

    body =
      Jason.encode!(
        generate_function_object(
          function_name,
          image_name,
          %{
            @min_scale_label => @min_scale_default,
            @max_scale_label => to_string(replicas),
            @scale_factor_label => @scale_factor_default
          }
        )
      )

    Logger.debug("Deploy Openfaas application \n#{url} : \n#{body}")

    Finch.build(
      :post,
      url,
      headers,
      body
    )
    |> Finch.request(AppHttp, receive_timeout: 1000)
    |> response(:deploy_app)
    |> case do
      {:ok, _} = res ->
        Logger.debug("Openfaas application deployed")
        res

      err ->
        Logger.error("Error while deploying application : #{inspect(err)}")
        err
    end
  end

  @doc """
  Start an OpenFaaS application.
  """
  @spec start_app(String.t()) :: :ok | {:error, struct} | {:ok, any}
  def start_app(function_name) do
    Logger.info("Start Openfaas application #{function_name}")
    set_app_min_scale(function_name, 1)
  end

  @doc """
  Stop an OpenFaaS application.
  """
  @spec stop_app(String.t()) :: :ok | {:error, struct} | {:ok, any}
  def stop_app(function_name) do
    Logger.info("Stop Openfaas application #{function_name}")
    set_app_min_scale(function_name, 0)
  end

  @doc """
  Set the minimum scale of an OpenFaaS application.
  """
  @spec set_app_min_scale(String.t(), integer()) :: :ok | {:error, struct} | {:ok, any}
  def set_app_min_scale(function_name, min_scale) do
    set_app_labels(function_name, %{@min_scale_label => to_string(min_scale)})
  end

  @doc """
  Set the maximum scale of an OpenFaaS application.
  """
  @spec set_app_max_scale(String.t(), integer()) :: :ok | {:error, struct} | {:ok, any}
  def set_app_max_scale(function_name, max_scale) do
    set_app_labels(function_name, %{@max_scale_label => to_string(max_scale)})
  end

  @doc """
  Set the maximum scale of an OpenFaaS application.
  """
  @spec set_app_scale_factor(String.t(), integer()) :: :ok | {:error, struct} | {:ok, any}
  def set_app_scale_factor(function_name, scale_factor) when scale_factor in [0, 100] do
    set_app_labels(function_name, %{@scale_factor_label => to_string(scale_factor)})
  end

  @doc """
  Get the status of an application from OpenFaaS.
  """
  @spec get_app_status(String.t()) :: :ok | {:error, struct} | {:ok, any}
  def get_app_status(function_name) do
    {base_url, headers} = get_http_context()

    url = "#{base_url}/system/function/#{function_name}"

    Logger.debug("Get Openfaas application #{function_name} status")

    Finch.build(
      :get,
      url,
      headers
    )
    |> Finch.request(AppHttp, receive_timeout: 5000)
    |> response(:get_app)
  end

  @doc """
  Set the labels of an OpenFaaS application.
  """
  @spec set_app_labels(String.t(), map()) :: :ok | {:error, struct} | {:ok, any}
  def set_app_labels(function_name, labels) do
    {base_url, headers} = get_http_context()

    url = "#{base_url}/system/functions"

    case get_app_status(function_name) do
      {:ok, app} ->
        body =
          Jason.encode!(
            generate_function_object(
              function_name,
              app["image"],
              Map.merge(Map.get(app, :labels, %{}), labels)
            )
          )

        Logger.debug("Set Openfaas application #{function_name} labels \n#{inspect(labels)}")

        Finch.build(
          :put,
          url,
          headers,
          body
        )
        |> Finch.request(AppHttp, receive_timeout: 5000)
        |> response(:update_app)
        |> case do
          {:ok, _} = res ->
            Logger.debug("Openfaas application updated")
            res

          err ->
            Logger.error("Error while updating application : #{inspect(err)}")
            err
        end

      _ ->
        TechnicalError.openfaas_not_reachable_tuple()
    end
  end

  defp response({:ok, acc}, :resource) do
    {:ok, acc}
  end

  defp response({:ok, %Finch.Response{status: 200, body: body}}, key)
       when key in [:manifest, :view] do
    {:ok, Jason.decode!(body)}
  end

  defp response({:ok, %Finch.Response{status: 200}}, :listener) do
    :ok
  end

  defp response({:ok, %Finch.Response{status: status_code}}, :deploy_app)
       when status_code in [200, 202] do
    {:ok, status_code}
  end

  defp response({:ok, %Finch.Response{status: status_code}}, :update_app)
       when status_code in [200, 202] do
    {:ok, status_code}
  end

  defp response({:ok, %Finch.Response{status: 200, body: body}}, :get_app) do
    {:ok, Jason.decode!(body)}
  end

  defp response({:error, %Mint.TransportError{reason: reason}}, listener) do
    Telemetry.event(
      :alert,
      %{listener: listener},
      TechnicalError.openfaas_not_reachable(reason)
    )

    TechnicalError.openfaas_not_reachable_tuple()
  end

  defp response(
         {:ok, %Finch.Response{status: status_code, body: body}},
         listener
       )
       when status_code not in [200, 202] do
    case status_code do
      400 ->
        Telemetry.event(:alert, %{listener: listener}, TechnicalError.bad_request(body))
        TechnicalError.bad_request_tuple(body)

      404 ->
        Logger.error(TechnicalError.error_404(body))
        TechnicalError.error_404_tuple(body)

      500 ->
        formated_error =
          body
          |> Errors.format_error_with_stacktrace()
          |> TechnicalError.error_500()

        Telemetry.event(:alert, %{listener: listener}, formated_error)
        TechnicalError.error_500_tuple(body)

      504 ->
        Logger.error(TechnicalError.timeout(body))
        TechnicalError.timeout_tuple(body)

      err ->
        # maybe alert ?
        err
        |> Errors.format_error_with_stacktrace()
        |> TechnicalError.unknown_error()
        |> Logger.critical()

        TechnicalError.unknown_error_tuple(body)
    end
  end
end
