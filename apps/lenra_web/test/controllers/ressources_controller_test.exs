defmodule LenraWeb.RessourcesControllerTest do
  use LenraWeb.ConnCase, async: true

  alias Lenra.Apps.App
  alias Lenra.Repo

  setup %{conn: conn} do
    {:ok, conn: conn}

    Bypass.open(port: 1234)
    |> Bypass.stub("POST", "/function/#{@function_name}", &handle_resp/1)
  end

  defp handle_resp(conn) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    case Jason.decode(body) do
      {:ok, _json} ->
        Plug.Conn.resp(
          conn,
          200,
          Jason.encode!("image")
        )

      {:error, _} ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{manifest: @manifest}))
    end
  end

  describe "index" do
    test "apps resource", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.resources_path(conn, :get_app_resource,
            app_name: "test",
            resource: "test"
          )
        )

      assert json_response(conn, 401) == %{
               "message" => "You are not authenticated",
               "reason" => "unauthenticated"
             }
    end

    test "apps resource sub directory", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.resources_path(conn, :get_app_resource,
            app_name: "test",
            resource: "image/test"
          )
        )

      assert json_response(conn, 401) == %{
               "message" => "You are not authenticated",
               "reason" => "unauthenticated"
             }
    end
  end
end
