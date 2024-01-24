defmodule LenraWeb.RoutesChannelTest do
  use ApplicationRunner.ChannelCase, async: true

  alias ApplicationRunner.RoutesChannel
  alias LenraWeb.RoutesChannelTest.FakeManifestHandler
  alias ApplicationRunner.Environment.ManifestHandler
  alias ApplicationRunner.Repo
  alias ApplicationRunner.FakeRoutesChannel
  alias ApplicationRunner.{Contract, Environment}

  @function_name Ecto.UUID.generate()
  @session_id 13456

  setup do
    {:ok, %{id: env_id}} = Repo.insert(Contract.Environment.new())

    on_exit(fn ->
      Swarm.unregister_name(ManifestHandler.get_full_name(env_id))
    end)

    {:ok, env_id: env_id,}
  end

  describe "join" do

    test "lenra not authenticated", %{env_id: env_id} do

      socket =
        ApplicationRunner.FakeAppSocket
        |> socket("/socket", %{env_id: env_id, session_id: @session_id, roles: ["guest"]})
      manifest =  [
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

      GenServer.start_link(FakeManifestHandler, [manifest: manifest], name: ManifestHandler.get_full_name(env_id))

      assert {:ok,%{ "lenraRoutes" => routes, }, socket} = subscribe_and_join(socket, FakeRoutesChannel, "routes", %{"mode" => "lenra"})
      assert [%{
        "view" => %{
        "name" => "guestMain",
        }
      }] = routes
    end

    @tag auth_user_with_cgs: :user
    test "lenra authenticated", %{env_id: env_id} do


      socket =
        ApplicationRunner.FakeAppSocket
        |> socket("/socket", %{env_id: env_id, session_id: @session_id, roles: ["user"]})
      manifest =  [
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

      GenServer.start_link(FakeManifestHandler, [manifest: manifest], name: ManifestHandler.get_full_name(env_id))

      assert {:ok,%{ "lenraRoutes" => routes, }, socket} = subscribe_and_join(socket, FakeRoutesChannel, "routes", %{"mode" => "lenra"})
      assert [%{
        "view" => %{
        "name" => "main",
        }
      }] = routes
    end
  end

  defp handle_manifest_resp(conn, manifest) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)


    case Jason.decode(body) do
      {:ok, _json} ->
        Plug.Conn.resp(
          conn,
          200,
          Jason.encode!(%{view: @view})
        )

      {:error, _} ->
        Plug.Conn.resp(conn, 200, Jason.encode!(manifest))
    end
  end

  defmodule FakeManifestHandler do
    use GenServer

    def start_link(_) do
      GenServer.start_link(__MODULE__, [])
    end

    def init([manifest: manifest]) do
      {:ok, %{manifest: manifest}}
    end


    def handle_call(request, from, state) do
      manifest = Map.fetch!(state, :manifest)
      {:reply, manifest, state}
    end
  end
end
