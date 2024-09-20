defmodule ApplicationRunner.ApplicationServicesTest do
  use ApplicationRunner.ConnCase, async: false
  import TelemetryTest

  alias ApplicationRunner.ApplicationServices

  setup [:telemetry_listen]

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

  @tag telemetry_listen: [:application_runner, :alert, :event]
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

    assert_received(
      {:telemetry_event,
       %{
         event: [:application_runner, :alert, :event],
         measurements: %LenraCommon.Errors.TechnicalError{
           __exception__: true,
           message: "Internal server error.",
           reason: :error_500,
           status_code: 500
         },
         metadata: %{}
       }}
    )
  end

  @tag telemetry_listen: [:application_runner, :alert, :event]
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

    assert_received(
      {:telemetry_event,
       %{
         event: [:application_runner, :alert, :event],
         measurements: %LenraCommon.Errors.TechnicalError{
           __exception__: true,
           message: "Internal server error.",
           reason: :error_500,
           status_code: 500
         },
         metadata: %{}
       }}
    )
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

  @tag telemetry_listen: [:application_runner, :alert, :event]
  test "failing fetch_view" do
    bypass = Bypass.open(port: 1234)

    Bypass.expect_once(
      bypass,
      "POST",
      "/function/#{@function_name}",
      &handle_error_resp/1
    )

    result = ApplicationServices.fetch_view(@function_name, "test", %{}, %{}, %{})

    assert {
             :error,
             %LenraCommon.Errors.TechnicalError{
               reason: :error_500,
               __exception__: true,
               message: "Internal server error.",
               metadata: "error",
               status_code: 500
             }
           } = result

    refute_received(
      {:telemetry_event,
       %{
         event: [:application_runner, :alert, :event],
         measurements: %LenraCommon.Errors.TechnicalError{
           __exception__: true,
           message: "Internal server error.",
           reason: :error_500,
           status_code: 500
         },
         metadata: %{}
       }},
      "The alert event should not be sent when the fetch_view fails"
    )
  end
end
