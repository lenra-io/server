defmodule ApplicationRunner.ApplicationServicesTest do
  use ApplicationRunner.ConnCase, async: false

  alias ApplicationRunner.ApplicationServices

  @function_name Ecto.UUID.generate()

  defp handle_resp(conn) do
    Plug.Conn.resp(conn, 200, "ok")
  end

  defp handle_error_resp(conn) do
    Plug.Conn.resp(conn, 500, "error")
  end

  defp app_info_handler(app \\ %{name: @function_name}) do
    fn conn ->
      Plug.Conn.resp(conn, 200, Jason.encode!(app))
    end
  end

  test "start app" do
    bypass = Bypass.open(port: 1234)
    Bypass.stub(bypass, "GET", "/system/function/#{@function_name}", app_info_handler())
    Bypass.stub(bypass, "PUT", "/system/functions", &handle_resp/1)

    # Check scale up
    Bypass.expect_once(
      bypass,
      "PUT",
      "/system/functions",
      fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        app = Jason.decode!(body)

        assert "1" = app["labels"]["com.openfaas.scale.min"]

        conn
        |> send_resp(200, "ok")
      end
    )

    ApplicationServices.start_app(@function_name)
  end

  test "stop app" do
    bypass = Bypass.open(port: 1234)
    Bypass.stub(bypass, "GET", "/system/function/#{@function_name}", app_info_handler())
    Bypass.stub(bypass, "PUT", "/system/functions", &handle_resp/1)

    # Check scale up
    Bypass.expect_once(
      bypass,
      "PUT",
      "/system/functions",
      fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        app = Jason.decode!(body)

        assert "1" = app["labels"]["com.openfaas.scale.min"]

        conn
        |> send_resp(200, "ok")
      end
    )

    ApplicationServices.start_app(@function_name)
  end

  test "failing app info while stating app" do
    bypass = Bypass.open(port: 1234)
    Bypass.stub(bypass, "GET", "/system/function/#{@function_name}", &handle_error_resp/1)

    result = ApplicationServices.start_app(@function_name)

    assert {
             :error,
             %LenraCommon.Errors.TechnicalError{
               reason: :openfaas_not_reachable
             }
           } = result
  end

  test "failing app info while stoping app" do
    bypass = Bypass.open(port: 1234)
    Bypass.stub(bypass, "GET", "/system/function/#{@function_name}", &handle_error_resp/1)

    result = ApplicationServices.stop_app(@function_name)

    assert {
             :error,
             %LenraCommon.Errors.TechnicalError{
               reason: :openfaas_not_reachable
             }
           } = result
  end

  test "fetch_view" do
    bypass = Bypass.open(port: 1234)

    # Check view fetch request
    Bypass.expect_once(
      bypass,
      "POST",
      "/function/#{@function_name}",
      fn conn ->
        content_length = Plug.Conn.get_req_header(conn, "content-length")
        assert ["49"] = content_length

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        app = Jason.decode!(body)
        assert "test" = app["view"]

        conn
        |> send_resp(200, body)
      end
    )

    ApplicationServices.fetch_view(@function_name, "test", %{}, %{}, %{})
  end

  test "fetch_view with accent" do
    bypass = Bypass.open(port: 1234)

    # Check view fetch request
    Bypass.expect_once(
      bypass,
      "POST",
      "/function/#{@function_name}",
      fn conn ->
        content_length = Plug.Conn.get_req_header(conn, "content-length")
        assert ["51"] = content_length

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        app = Jason.decode!(body)
        assert "testé" = app["view"]

        conn
        |> send_resp(200, body)
      end
    )

    ApplicationServices.fetch_view(@function_name, "testé", %{}, %{}, %{})
  end
end
