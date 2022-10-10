defmodule LenraWeb.WebhooksController do
  use LenraWeb, :controller

  alias ApplicationRunner.Webhooks.WebhookServices
  alias Lenra.Errors.BusinessError

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
end
