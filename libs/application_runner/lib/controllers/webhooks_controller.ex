defmodule ApplicationRunner.Webhooks.WebhooksController do
  use ApplicationRunner, :controller

  alias ApplicationRunner.Errors.BusinessError
  alias ApplicationRunner.Webhooks.WebhookServices

  require Logger

  def create(conn, params) do
    Logger.debug(
      "#{__MODULE__} handle #{inspect(conn.method)} on #{inspect(conn.request_path)} with path_params #{inspect(conn.path_params)} and body_params #{inspect(conn.body_params)}"
    )

    with {:ok, webhook} <-
           Guardian.Plug.current_resource(conn)
           |> WebhookServices.app_create(params) do
      conn
      |> reply(webhook)
    end
  end
end
