defmodule LenraWeb.WebhooksController do
  use LenraWeb, :controller

  def index(conn, %{"env_id" => env_id, "user_id" => user_id} = params) do
    conn
    |> reply(ApplicationRunner.Webhooks.WebhookServices.get(env_id, user_id))
  end

  def index(conn, %{"env_id" => env_id} = params) do
    conn
    |> reply(ApplicationRunner.Webhooks.WebhookServices.get(env_id))
  end

  def index(_conn, _params) do
    {:error, :null_parameters}
  end
end
