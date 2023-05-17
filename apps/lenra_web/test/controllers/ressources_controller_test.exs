defmodule LenraWeb.RessourcesControllerTest do
  use LenraWeb.ConnCase, async: true

  alias Ecto.UUID
  alias Lenra.Apps.App
  alias Lenra.Repo

  setup %{conn: conn} do
    Bypass.open(port: 1234)
    |> Bypass.stub("POST", "/function/#{@function_name}", &handle_resp/1)

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
    @tag auth_user_with_cgu: :dev
    test "apps resource", %{conn: conn} do
      {"authorization", t} = List.keyfind(conn.req_headers, "authorization", 0)
      [_ | [t | _]] = String.split(t)
      uuid = UUID.generate()

      conn = put_req_header(conn, "content-type", "application/json")

      conn =
        get(
          conn,
          "/api/apps/" <> uuid <> "/resources/test?token=" <> t
        )

      assert json_response(conn, 200) == %{}
    end

    @tag auth_user_with_cgu: :dev
    test "apps resource sub directory", %{conn: conn} do
      {"authorization", t} = List.keyfind(conn.req_headers, "authorization", 0)
      [_ | [t | _]] = String.split(t)
      uuid = UUID.generate()

      conn =
        get(
          conn,
          "/api/apps/" <> uuid <> "/resources/image/test?token=" <> t
        )

      assert json_response(conn, 200) == %{}
    end
  end
end
