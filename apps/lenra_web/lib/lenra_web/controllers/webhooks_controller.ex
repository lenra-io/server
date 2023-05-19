defmodule LenraWeb.WebhooksController do
  use LenraWeb, :controller

  alias ApplicationRunner.Webhooks.WebhookServices
  alias Lenra.Apps.Webhook
  alias Lenra.Errors.BusinessError
  alias Lenra.Repo

  require Logger

  def index(conn, %{"env_id" => env_id, "user_id" => user_id}) do
    conn
    |> reply(WebhookServices.get(env_id, user_id))
  end

  def index(conn, %{"env_id" => env_id}) do
    conn
    |> reply(WebhookServices.get(env_id))
  end

  def index(_conn, _params) do
    BusinessError.null_parameters_tuple()
  end

  def api_create(conn, %{"env_id" => env_id} = params) do
    with {:ok, webhook} <- WebhookServices.create(env_id, params) do
      conn
      |> reply(webhook)
    end
  end

  def api_create(_conn, _params) do
    BusinessError.null_parameters_tuple()
  end

  def trigger(conn, %{"app_uuid" => app_uuid, "webhook_uuid" => webhook_uuid} = _params) do
    Logger.debug(
      "#{__MODULE__} handle #{inspect(conn.method)} on #{inspect(conn.request_path)} with path_params #{inspect(conn.path_params)} and body_params #{inspect(conn.body_params)}"
    )

    with %ApplicationRunner.Webhooks.Webhook{} = webhook <-
           webhook_uuid
           |> WebhookServices.get_by_uuid(),
         %Webhook{} = embedded <- Webhook.embed(webhook),
         preloaded <- Repo.preload(embedded, environment: [:application]),
         true <- preloaded.environment.application.service_name == app_uuid do
      conn
      |> reply(WebhookServices.trigger(webhook_uuid, conn.body_params))
    else
      _ -> Lenra.Errors.TechnicalError.error_404_tuple()
    end
  end

  def trigger(_conn, params) do
    Logger.error(BusinessError.null_parameters_tuple(params))
    BusinessError.null_parameters_tuple(params)
  end
end
