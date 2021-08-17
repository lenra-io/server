defmodule LenraWeb.HealthController do
  use LenraWeb, :controller

  def index(conn, _params) do
    conn
    |> send_resp(200, "")
    |> halt()
  end
end
