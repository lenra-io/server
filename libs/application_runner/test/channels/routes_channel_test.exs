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

  setup %{socket: socket, env_id: env_id, session_id: session_id} do
    GenServer.start_link(
      ApplicationRunner.StateInjectedGenServer,
      [state: @guest_and_roleless_routes],
      name: ManifestHandler.get_full_name(env_id)
    )

    on_exit(fn ->
      Swarm.unregister_name(ManifestHandler.get_full_name(env_id))
    end)

    {:ok, socket: socket, env_id: env_id, session_id: session_id}
  end

  describe "join" do
    test "lenra not authenticated", %{socket: socket} do
      assert {:ok,
              %{
                "lenraRoutes" => [
                  %{
                    "view" => %{
                      "name" => "guestMain"
                    }
                  }
                ]
              },
              socket} =
               subscribe_and_join(socket, FakeRoutesChannel, "routes", %{"mode" => "lenra"})
    end

    @tag user: "user"
    test "lenra authenticated", %{env_id: env_id} do
      assert {:ok,
              %{
                "lenraRoutes" => [
                  %{
                    "view" => %{
                      "name" => "main"
                    }
                  }
                ]
              },
              socket} =
               subscribe_and_join(socket, FakeRoutesChannel, "routes", %{"mode" => "lenra"})
    end
  end
end
