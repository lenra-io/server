defmodule LenraWeb.ResourcesController do
  use LenraWeb, :controller

  alias Lenra.Guardian.Plug
  alias Lenra.ResourcesServices

  def get_app_resource(conn, %{"service_name" => service_name, "resource" => resource_name}) do
    user = Plug.current_resource(conn)

    {:ok, resource_stream} = ResourcesServices.get(user.id, service_name, resource_name)

    conn =
      conn
      |> put_resp_content_type("image/event-stream")
      |> put_resp_header("Content-Type", "application/octet-stream")
      |> send_chunked(200)

    Enum.reduce(resource_stream, conn, fn
      {:data, data}, conn ->
        {:ok, conn_res} = chunk(conn, data)
        conn_res

      _no_data, conn ->
        conn
    end)
  end
end
