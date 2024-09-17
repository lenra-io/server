defmodule LenraWeb.RoutesChannelTest do
  use ApplicationRunner.ChannelCase, async: true

  alias ApplicationRunner.FakeRoutesChannel

  @manifest %{
    "lenra" => %{
      "routes" => [
        %{
          "path" => "/",
          "view" => %{
            "_type" => "view",
            "name" => "guestMain"
          },
          "roles" => ["guest"]
        },
        %{
          "path" => "/",
          "view" => %{
            "_type" => "view",
            "name" => "main"
          }
        }
      ]
    }
  }

  setup %{create_socket: create_socket, openfaas_bypass: bypass, function_name: function_name} do
    Bypass.stub(bypass, "POST", "/function/#{function_name}", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      result =
        case Jason.decode!(body) do
          %{"view" => _view} ->
            %{}

          %{"listener" => _listener} ->
            %{}

          %{} ->
            @manifest
        end

      Plug.Conn.resp(conn, 200, Jason.encode!(result))
    end)

    {:ok, socket} = create_socket.(%{})

    on_exit(fn ->
      close(socket)
    end)

    {:ok, socket: socket, openfaas_bypass: bypass, function_name: function_name}
  end

  describe "join" do
    @tag telemetry_listen: [:application_runner, :app_listener, :start]
    test("lenra not authenticated", %{socket: socket}) do
      join_result = subscribe_and_join(socket, FakeRoutesChannel, "routes", %{"mode" => "lenra"})

      assert {:ok,
              %{
                "lenraRoutes" => [
                  %{
                    "view" => %{
                      "name" => "guestMain"
                    }
                  }
                ]
              }, _socket} = join_result
    end

    @tag :user
    @tag telemetry_listen: [:application_runner, :app_listener, :start]
    test "lenra authenticated", %{socket: socket} do
      join_result = subscribe_and_join(socket, FakeRoutesChannel, "routes", %{"mode" => "lenra"})

      assert {:ok,
              %{
                "lenraRoutes" => [
                  %{
                    "view" => %{
                      "name" => "main"
                    }
                  }
                ]
              }, _socket} = join_result
    end
  end
end
