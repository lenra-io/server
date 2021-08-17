defmodule LenraWeb.ResourcesController do
  use LenraWeb, :controller

  alias Lenra.ResourcesServices
  alias Lenra.Guardian.Plug

  def get_app_resource(conn, %{"service_name" => service_name, "resource" => resource_name}) do
    user = Plug.current_resource(conn)

    {:ok, resource_stream} = ResourcesServices.get(user.id, service_name, resource_name)

    conn =
      conn
      |> put_resp_content_type("image/event-stream")
      |> put_resp_header("Content-Type", "application/octet-stream")
      |> send_chunked(200)

    resource_stream
    |> Enum.reduce(conn, fn
      {:data, data}, conn ->
        {:ok, conn_res} =
          conn
          |> chunk(data)

        conn_res

      _, conn ->
        conn
    end)
  end
end
