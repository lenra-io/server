defmodule LenraWeb.ResourcesControllerTest do
  use ApplicationRunner.ConnCase, async: true

  alias Ecto.UUID

  setup %{conn: conn} do
    Bypass.open(port: 1234)
    |> Bypass.expect_once("POST", "/function/function_name", &handle_resp/1)

    {:ok, conn: conn}
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
      uuid = UUID.generate()
      conn = get(conn, "/api/apps/" <> uuid <> "/resources/test")
      assert response(conn, 200)
    end

    @tag auth_user_with_cgu: :dev
    test "apps resource sub directory", %{conn: conn} do
      uuid = UUID.generate()

      conn = get(conn, "/api/apps/" <> uuid <> "/resources/image/test")

      assert response(conn, 200)
    end
  end
end
