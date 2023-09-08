defmodule ApplicationRunner.IntegrationTest do
  use ApplicationRunner.ConnCase, async: false

  alias ApplicationRunner.Guardian.AppGuardian

  alias ApplicationRunner.{
    Contract,
    Environment,
    MongoStorage,
    RouteChannel,
    Session,
    Telemetry
  }

  @session_id Ecto.UUID.generate()
  @function_name Ecto.UUID.generate()
  @url "/function/#{@function_name}"

  @mode "lenra"
  @route "/"
  @coll "test_integration"
  @query %{"foo" => "bar"}

  @manifest %{
    "lenraRoutes" => [
      %{"path" => "/", "view" => %{"type" => "view", "name" => "main"}}
    ]
  }

  def view("main", _) do
    %{"type" => "view", "name" => "echo", "query" => @query, "coll" => @coll}
  end

  def view("echo", data) do
    %{"type" => "text", "value" => Jason.encode!(data)}
  end

  def get_name(module, identifier) do
    {module, identifier}
  end

  setup ctx do
    Application.ensure_all_started(:postgrex)
    start_supervised(ApplicationRunner.Repo)

    ctx = Map.merge(ctx, setup_db(ctx))
    ctx = Map.merge(ctx, setup_logger_agent(ctx))
    ctx = Map.merge(ctx, setup_env_metadata(ctx))
    ctx = Map.merge(ctx, setup_session_metadata(ctx))
    ctx = Map.merge(ctx, setup_bypass(ctx))
    ctx = Map.merge(ctx, setup_genservers(ctx))

    {:ok, ctx}
  end

  def setup_genservers(%{session_metadata: sm, env_metadata: em}) do
    # Self must join AppSocket group to receive new UI
    Swarm.register_name(get_name(RouteChannel, {sm.session_id, @mode, @route}), self())
    Swarm.join(RouteChannel.get_group(sm.session_id, @mode, @route), self())

    # Start env
    Environment.DynamicSupervisor.ensure_env_started(em)

    start_supervised({Environment.TokenAgent, em})

    # Reset and setup mongo coll
    mongo_name = Environment.MongoInstance.get_full_name(em.env_id)
    Mongo.drop_collection(mongo_name, @coll)

    %{}
  end

  def setup_db(_ctx) do
    {:ok, env} = ApplicationRunner.Repo.insert(Contract.Environment.new(%{}))
    {:ok, user} = ApplicationRunner.Repo.insert(Contract.User.new(%{email: "test@test.te"}))
    %{user: user, env: env}
  end

  def setup_session_metadata(%{env: env, user: user}) do
    %{
      session_metadata: %Session.Metadata{
        env_id: env.id,
        user_id: user.id,
        session_id: @session_id,
        function_name: @function_name,
        context: %{}
      }
    }
  end

  def setup_env_metadata(%{env: env}) do
    %{
      env_metadata: %Environment.Metadata{
        env_id: env.id,
        function_name: @function_name
      }
    }
  end

  def setup_logger_agent(_ctx) do
    {:ok, pid} = start_supervised({Agent, fn -> [] end})
    %{logger_agent: pid}
  end

  def add_log_to_agent(logger_agent, log) do
    Agent.update(logger_agent, fn logs -> logs ++ [log] end)
  end

  def get_logs(logger_agent) do
    Agent.get(logger_agent, fn logs -> logs end)
  end

  def setup_bypass(%{logger_agent: logger_agent, session_metadata: sm}) do
    bypass = Bypass.open(port: 1234)
    Bypass.stub(bypass, "GET", "/system/function/#{@function_name}", &resp_app_info/1)
    Bypass.stub(bypass, "PUT", "/system/functions", &resp_update/1)

    Bypass.stub(bypass, "POST", @url, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      uuid = Ecto.UUID.generate()

      {:ok, token, _claims} =
        AppGuardian.encode_and_sign(uuid, %{
          type: "session",
          env_id: sm.env_id,
          user_id: sm.user_id
        })

      Environment.TokenAgent.add_token(sm.env_id, uuid, token)

      case Jason.decode(body) do
        {:ok, %{"action" => action, "props" => props}} ->
          resp_listener(logger_agent, conn, action, props, token)

        {:ok, %{"view" => name, "data" => data}} ->
          resp_view(logger_agent, conn, name, data)

        {:ok, %{}} ->
          resp_manifest(logger_agent, conn)

        {:error, _} ->
          resp_manifest(logger_agent, conn)
      end
    end)

    %{bypass: bypass}
  end

  def resp_app_info(conn) do
    Plug.Conn.resp(conn, 200, Jason.encode!(%{name: @function_name, label: %{}}))
  end

  def resp_update(conn) do
    Plug.Conn.resp(conn, 200, Jason.encode!(%{}))
  end

  def resp_manifest(logger_agent, conn) do
    add_log_to_agent(logger_agent, {:manifest, @manifest})
    Plug.Conn.resp(conn, 200, Jason.encode!(%{manifest: @manifest}))
  end

  def resp_view(logger_agent, conn, name, data) do
    add_log_to_agent(logger_agent, {:view, name, data})

    Plug.Conn.resp(
      conn,
      200,
      Jason.encode!(%{view: view(name, data)})
    )
  end

  def resp_listener(logger_agent, conn, action, props, token) do
    add_log_to_agent(logger_agent, {:listener, action, props})

    case action do
      "insert" ->
        conn = Phoenix.ConnTest.build_conn()

        conn =
          conn
          |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
          |> post(Routes.docs_path(conn, :create, @coll), props)

        assert %{} = json_response(conn, 200)

      "update" ->
        conn = Phoenix.ConnTest.build_conn()

        conn =
          conn
          |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
          |> get(Routes.docs_path(conn, :get_all, @coll))

        assert [%{"_id" => doc_id}] = json_response(conn, 200)

        conn = Phoenix.ConnTest.build_conn()

        conn =
          conn
          |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
          |> put(Routes.docs_path(conn, :update, @coll, doc_id), props)

        assert %{} = json_response(conn, 200)

      "delete" ->
        conn = Phoenix.ConnTest.build_conn()

        conn =
          conn
          |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
          |> get(Routes.docs_path(conn, :get_all, @coll))

        assert [%{"_id" => doc_id}] = json_response(conn, 200)

        conn = Phoenix.ConnTest.build_conn()

        conn =
          conn
          |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
          |> delete(Routes.docs_path(conn, :delete, @coll, doc_id))

        assert %{} = json_response(conn, 200)

      _ ->
        nil
    end

    Plug.Conn.resp(
      conn,
      200,
      Jason.encode!(%{})
    )
  end

  test "Integration test, check that the UI change when the mongo db coll change", %{
    env_metadata: em,
    session_metadata: sm,
    logger_agent: logger_agent
  } do
    # The mongo_user_link should not exist before starting the session
    assert not MongoStorage.has_user_link?(em.env_id, sm.user_id)

    Telemetry.start(:app_session, sm)
    # Start the session and start one view
    {:ok, _} = Session.start_session(sm, em)
    {:ok, _} = Session.RouteDynSup.ensure_child_started(sm.env_id, sm.session_id, @mode, @route)

    # The mongo_user_link should have been creating when starting session.
    assert MongoStorage.has_user_link?(em.env_id, sm.user_id)

    # The first message should be a send ui message..
    assert_receive {:send, :ui, %{"root" => %{"type" => "text", "value" => "[]"}}}

    # Add one data by simulating an "insert" event.
    ApplicationRunner.EventHandler.send_session_event(
      sm.session_id,
      "insert",
      %{"foo" => "bar"},
      %{}
    )

    # The second message should be a send patches message..
    assert_receive {
      :send,
      :patches,
      [
        %{
          "value" => value,
          "op" => "replace",
          "path" => "/root/value"
        }
      ]
    }

    assert [%{"foo" => "bar"}] = Jason.decode!(value)

    # update the data by simulating an "update" event.
    ApplicationRunner.EventHandler.send_session_event(
      sm.session_id,
      "update",
      %{"foo" => "baz"},
      %{}
    )

    # The third message should be a send patches message..
    # The data should not appear since the query filter it.
    assert_receive {:send, :patches,
                    [
                      %{
                        "value" => "[]",
                        "op" => "replace",
                        "path" => "/root/value"
                      }
                    ]}

    # update the data again to make it match the query again.
    ApplicationRunner.EventHandler.send_session_event(
      sm.session_id,
      "update",
      %{"foo" => "bar"},
      %{}
    )

    # The data should appear again.
    assert_receive {:send, :patches,
                    [
                      %{
                        "value" => value,
                        "op" => "replace",
                        "path" => "/root/value"
                      }
                    ]}

    assert [%{"foo" => "bar"}] = Jason.decode!(value)

    # delete the data by simulating an "delete" event.
    ApplicationRunner.EventHandler.send_session_event(
      sm.session_id,
      "delete",
      %{},
      %{}
    )

    # The data should not disapear since it have been deleted.
    assert_receive {:send, :patches,
                    [
                      %{
                        "value" => "[]",
                        "op" => "replace",
                        "path" => "/root/value"
                      }
                    ]}

    # check the agent logger.
    # The logs should be in a specific order.
    assert [
             # First, the env starts...
             # The manifest is fetched
             {:manifest,
              %{
                "lenraRoutes" => [
                  %{"path" => "/", "view" => %{"type" => "view", "name" => "main"}}
                ]
              }},
             # The onEnvStart event is run.
             {:listener, "onEnvStart", %{}},
             # Then the session starts.
             # The onUserFirstJoin event is run
             {:listener, "onUserFirstJoin", %{}},
             # The onSessionStart event is run
             {:listener, "onSessionStart", %{}},
             # The UiServer get the UI for the first time during startup.
             # The first view "main" is fetched
             {:view, "main", []},
             # The second view "echo" is fetched because the main link to it. The data is empty.
             {:view, "echo", []},

             # We then simulate an insert listener.
             {:listener, "insert", %{"foo" => "bar"}},

             # Only the "echo" view is fetched again because "main" is cached.
             {:view, "echo", [%{"_id" => _, "foo" => "bar"}]},

             # We then simulate an update listener.
             {:listener, "update", %{"foo" => "baz"}},
             # Again, only echo. This time, the query does not match the data anymore.
             {:view, "echo", []},

             # We then simulate an update listener to revert the changes.
             {:listener, "update", %{"foo" => "bar"}},

             # Again, only echo. The query does match the data again.
             {:view, "echo", [%{"_id" => _, "foo" => "bar"}]},

             # Finally, we simulate a delete listener to remove the data.
             {:listener, "delete", %{}},
             # The "echo" view update for the last time.
             {:view, "echo", []}
           ] = get_logs(logger_agent)

    on_exit(fn ->
      Session.stop_session(em.env_id, sm.session_id)
      Swarm.unregister_name(Session.Supervisor.get_name(sm.session_id))
    end)
  end
end
