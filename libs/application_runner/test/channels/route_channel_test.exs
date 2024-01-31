defmodule LenraWeb.RouteChannelTest do
  use ApplicationRunner.ChannelCase, async: true

  alias ApplicationRunner.RouteChannel
  alias ApplicationRunner.Environment.ManifestHandler
  alias ApplicationRunner.Repo
  alias ApplicationRunner.FakeRouteChannel
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
      {:ok, _, socket} =
        subscribe_and_join(socket, FakeRouteChannel, "route:/", %{"mode" => "lenra"})

      view = %{
        "_type" => "text",
        "text" => "Hello World"
      }

      assert_push("ui", view)
    end
  end
end
