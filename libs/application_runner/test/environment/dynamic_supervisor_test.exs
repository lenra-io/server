defmodule ApplicationRunner.Environment.DynamixSupervisorTest do
  use ApplicationRunner.RepoCase, async: false

  alias ApplicationRunner.Contract
  alias ApplicationRunner.Environment
  alias ApplicationRunner.Environment.DynamicSupervisor

  @function_name Ecto.UUID.generate()

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

  defp handle_app_info_resp(conn) do
    Plug.Conn.resp(conn, 200, Jason.encode!(%{name: @function_name}))
  end

  test "should scall to one on environment start and to zero on environment exit" do
    {:ok, %{id: env_id}} = Repo.insert(Contract.Environment.new())

    bypass = Bypass.open(port: 1234)
    Bypass.stub(bypass, "GET", "/system/function/#{@function_name}", &handle_app_info_resp/1)
    Bypass.stub(bypass, "PUT", "/system/functions", &handle_resp/1)
    Bypass.stub(bypass, "POST", "/function/#{@function_name}", &handle_resp/1)

    env_metadata = %Environment.Metadata{
      env_id: env_id,
      function_name: @function_name
    }

    on_exit(fn ->
      Swarm.unregister_name(Environment.Supervisor.get_name(env_id))
    end)

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

    {:ok, _pid} = DynamicSupervisor.ensure_env_started(env_metadata)

    my_pid = self()

    # Check scale down
    Bypass.expect_once(
      bypass,
      "PUT",
      "/system/functions",
      fn conn ->
        send(my_pid, :lookup)

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        app = Jason.decode!(body)

        assert "0" = app["labels"]["com.openfaas.scale.min"]

        conn
        |> send_resp(200, "ok")
      end
    )

    DynamicSupervisor.stop_env(env_id)

    assert_receive(:lookup, 500)
  end
end
