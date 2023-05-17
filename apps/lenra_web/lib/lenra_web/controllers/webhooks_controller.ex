defmodule LenraWeb.WebhooksController do
  use LenraWeb, :controller

  alias ApplicationRunner.Webhooks.WebhookServices
  alias Lenra.Errors.BusinessError

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

  def trigger(conn, %{"webhook_uuid" => uuid} = _params) do
    Logger.debug(
      "#{__MODULE__} handle #{inspect(conn.method)} on #{inspect(conn.request_path)} with path_params #{inspect(conn.path_params)} and body_params #{inspect(conn.body_params)}"
    )

    IO.inspect("TRIGGER OK")

    conn
    |> reply(IO.inspect(WebhookServices.trigger(uuid, conn.body_params)))
  end

  def trigger(_conn, params) do
    IO.inspect("TRIGGER NOT OK")
    Logger.error(BusinessError.null_parameters_tuple(params))
    BusinessError.null_parameters_tuple(params)
  end
end
