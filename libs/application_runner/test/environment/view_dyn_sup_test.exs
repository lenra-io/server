defmodule ApplicationRunner.Environment.ViewDynSupTest do
  use ApplicationRunner.RepoCase, async: false

  alias ApplicationRunner.Environment.{
    ViewDynSup,
    ViewServer,
    ViewUid
  }

  alias ApplicationRunner.{Contract, Environment}
  alias ApplicationRunner.Guardian.AppGuardian
  alias QueryParser.Parser

  @manifest %{"rootview" => "main"}
  @view %{"type" => "text", "value" => "test"}

  @function_name Ecto.UUID.generate()
  @session_id 1337

  setup do
    {:ok, %{id: env_id}} = Repo.insert(Contract.Environment.new())

    Bypass.open(port: 1234)
    |> Bypass.stub("POST", "/function/#{@function_name}", &handle_resp/1)

    env_metadata = %Environment.Metadata{
      env_id: env_id,
      function_name: @function_name
    }

    {:ok, _pid} = start_supervised({Environment.Supervisor, env_metadata})

    on_exit(fn ->
      Swarm.unregister_name(Environment.Supervisor.get_name(env_id))
    end)

    {:ok, env_id: env_id}
  end

  defp handle_resp(conn) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    case Jason.decode(body) do
      {:ok, _json} ->
        Plug.Conn.resp(
          conn,
          200,
          Jason.encode!(%{view: @view})
        )

      {:error, _} ->
        Plug.Conn.resp(conn, 200, Jason.encode!(%{manifest: @manifest}))
    end
  end

  describe "ApplicationRunner.Environments.ViewDynSup.ensure_child_started/2" do
    test "should start view genserver with valid opts", %{env_id: env_id} do
      view_uid = %ViewUid{
        name: "test",
        coll: "testcoll",
        query_parsed: Parser.parse!("{}"),
        query_transformed: %{},
        props: %{},
        context: %{},
        projection: %{}
      }

      assert :undefined != Swarm.whereis_name(Environment.ViewDynSup.get_name(env_id))

      assert {:ok, _pid} =
               ViewDynSup.ensure_child_started(
                 env_id,
                 @session_id,
                 @function_name,
                 view_uid
               )

      assert @view == ViewServer.fetch_view!(env_id, view_uid)
    end
  end
end
