defmodule LenraWeb.RoutesChannelTest do
  use ApplicationRunner.ChannelCase, async: true

  alias ApplicationRunner.RoutesChannel
  alias LenraWeb.RoutesChannelTest.FakeManifestHandler
  alias ApplicationRunner.Environment.ManifestHandler
  alias ApplicationRunner.Repo
  alias ApplicationRunner.FakeRoutesChannel
  alias ApplicationRunner.{Contract, Environment}

  @guest_and_roleless_routes [
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

  setup %{socket: socket} do
    env_id = socket.assigns.env_id

    GenServer.start_link(
      ApplicationRunner.StateInjectedGenServer,
      [state: @guest_and_roleless_routes],
      name: ManifestHandler.get_full_name(env_id)
    )

    on_exit(fn ->
      Swarm.unregister_name(ManifestHandler.get_full_name(env_id))
    end)

    {:ok, socket: socket}
  end

  describe "join" do
    test "lenra not authenticated", %{socket: socket} do
      IO.inspect(socket.assigns)
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
              }, socket} = join_result
    end

    @tag :user
    test "lenra authenticated", %{socket: socket} do
      IO.inspect(socket.assigns)
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
              }, socket} = join_result
    end
  end
end
