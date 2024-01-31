defmodule ApplicationRunner.DocsControllerTest do
  use ApplicationRunner.ConnCase

  alias ApplicationRunner.Contract
  alias ApplicationRunner.Environment
  alias ApplicationRunner.Guardian.AppGuardian

  @coll "controller_test"

  setup ctx do
    Application.ensure_all_started(:postgrex)
    start_supervised(ApplicationRunner.Repo)

    {:ok, env} = ApplicationRunner.Repo.insert(Contract.Environment.new(%{}))

    env_metadata = %Environment.Metadata{
      env_id: env.id,
      function_name: ""
    }

    {:ok, _} = start_supervised({Environment.MetadataAgent, env_metadata})
    {:ok, pid} = start_supervised({Mongo, Environment.MongoInstance.config(env.id)})

    start_supervised({Environment.TokenAgent, env_metadata})

    start_supervised(
      {Task.Supervisor,
       name:
         {:via, :swarm,
          {ApplicationRunner.Environment.MongoInstance.TaskSupervisor,
           Environment.MongoInstance.get_name(env.id)}}}
    )

    Mongo.drop_collection(pid, @coll)

    doc_id =
      Mongo.insert_one!(pid, @coll, %{"foo" => "bar"})
      |> Map.get(:inserted_id)
      |> Jason.encode!()
      |> Jason.decode!()

    uuid = Ecto.UUID.generate()
    {:ok, token, _claims} = AppGuardian.encode_and_sign(uuid, %{type: "env", env_id: env.id})

    Environment.TokenAgent.add_token(env.id, uuid, token)

    {:ok, Map.merge(ctx, %{mongo_pid: pid, token: token, doc_id: doc_id})}
  end

  describe "ApplicationRunner.DocsController.get_all" do
    test "should be protected with a token", %{conn: conn} do
      conn = get(conn, Routes.docs_path(conn, :get_all, @coll))

      assert %{"message" => _, "reason" => "unauthenticated"} = json_response(conn, 401)
    end

    test "Should return all docs", %{conn: conn, token: token} do
      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
        |> get(Routes.docs_path(conn, :get_all, @coll))

      assert [%{"foo" => "bar"}] = json_response(conn, 200)
    end
  end

  describe "ApplicationRunner.DocsController.get" do
    test "should be protected with a token", %{conn: conn, doc_id: doc_id} do
      conn = get(conn, Routes.docs_path(conn, :get, @coll, doc_id))

      assert %{"message" => _, "reason" => "unauthenticated"} = json_response(conn, 401)
    end

    test "Should return the correct doc", %{conn: conn, token: token, doc_id: doc_id} do
      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
        |> get(Routes.docs_path(conn, :get, @coll, doc_id))

      assert %{"foo" => "bar"} = json_response(conn, 200)
    end
  end

  describe "ApplicationRunner.DocsController.find" do
    test "should be protected with a token", %{conn: conn, doc_id: doc_id} do
      conn = post(conn, Routes.docs_path(conn, :find, @coll), %{"_id" => doc_id})

      assert %{"message" => _, "reason" => "unauthenticated"} = json_response(conn, 401)
    end

    test "Should return the correct doc", %{conn: conn, token: token, doc_id: doc_id} do
      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
        |> post(Routes.docs_path(conn, :find, @coll), %{"_id" => doc_id})

      assert [%{"foo" => "bar"}] = json_response(conn, 200)
    end

    test "Simple pagination should work", %{conn: conn, token: token, mongo_pid: pid} do
      coll = "pagination"

      Mongo.drop_collection(pid, coll)

      Enum.each(0..99, fn x ->
        Mongo.insert_one!(pid, coll, %{"id" => x})
      end)

      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
        |> post(Routes.docs_path(conn, :find, coll), %{
          "query" => %{},
          "options" => %{"limit" => 5}
        })

      paginated_res = json_response(conn, 200)
      assert Enum.count(paginated_res) == 5

      assert [%{"id" => 0}, %{"id" => 1}, %{"id" => 2}, %{"id" => 3}, %{"id" => 4}] =
               paginated_res
    end

    test "Pagination with limit & skip should work", %{conn: conn, token: token, mongo_pid: pid} do
      coll = "pagination"

      Mongo.drop_collection(pid, coll)

      Enum.each(0..99, fn x ->
        Mongo.insert_one!(pid, coll, %{"id" => x})
      end)

      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
        |> post(Routes.docs_path(conn, :find, coll), %{
          "query" => %{},
          "options" => %{"limit" => 5, "skip" => 5}
        })

      paginated_res = json_response(conn, 200)
      assert Enum.count(paginated_res) == 5

      assert [%{"id" => 5}, %{"id" => 6}, %{"id" => 7}, %{"id" => 8}, %{"id" => 9}] =
               paginated_res
    end

    test "Wrong options should return an error", %{conn: conn, token: token, mongo_pid: pid} do
      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
        |> post(Routes.docs_path(conn, :find, "test"), %{
          "query" => %{},
          "options" => %{"limitwrong" => 5, "skipwrong" => 5, "skip" => "wrong"}
        })

      paginated_res = json_response(conn, 400)
    end
  end

  describe "ApplicationRunner.DocsController.create" do
    test "should be protected with a token", %{conn: conn} do
      conn = post(conn, Routes.docs_path(conn, :create, @coll), %{"foo" => "bar"})

      assert %{"message" => _, "reason" => "unauthenticated"} = json_response(conn, 401)
    end

    test "Should create the new doc", %{conn: conn, token: token, mongo_pid: mongo_pid} do
      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
        |> post(Routes.docs_path(conn, :create, @coll), %{"foo" => "baz"})

      assert %{} = json_response(conn, 200)

      assert [%{"foo" => "bar"}, %{"foo" => "baz"}] =
               Mongo.find(mongo_pid, @coll, %{}) |> Enum.to_list()
    end
  end

  describe "ApplicationRunner.DocsController.insert_many" do
    test "Should insert multiple docs", %{
      conn: conn,
      token: token,
      mongo_pid: mongo_pid
    } do
      assert {:ok, body} = Jason.encode(%{"documents" => [%{"foo" => "bar"}, %{"foo" => "baz"}]})

    Mongo.drop_collection(mongo_pid, @coll)

      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> post(Routes.docs_path(conn, :insert_many, @coll), body)

      assert %{"insertedIds" => ids} = json_response(conn, 200)

      assert length(ids) == 2

      assert [%{"foo" => "bar"}, %{"foo" => "baz"}] =
               Mongo.find(mongo_pid, @coll, %{}) |> Enum.to_list()
    end
  end

  describe "ApplicationRunner.DocsController.update" do
    test "should be protected with a token", %{conn: conn, doc_id: doc_id} do
      conn = put(conn, Routes.docs_path(conn, :update, @coll, doc_id), %{"foo" => "bar"})

      assert %{"message" => _, "reason" => "unauthenticated"} = json_response(conn, 401)
    end

    test "Should update the doc", %{
      conn: conn,
      token: token,
      doc_id: doc_id,
      mongo_pid: mongo_pid
    } do
      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
        |> put(Routes.docs_path(conn, :update, @coll, doc_id), %{"foo" => "baz"})

      assert %{} = json_response(conn, 200)

      assert [%{"foo" => "baz"}] = Mongo.find(mongo_pid, @coll, %{}) |> Enum.to_list()
    end
  end

  describe "ApplicationRunner.DocsController.updateMany" do
    test "should be protected with a token", %{conn: conn, doc_id: _doc_id} do
      conn =
        post(conn, Routes.docs_path(conn, :update_many, @coll), %{
          filter: %{"foo" => "bar"},
          update: %{"$set" => %{"foo" => "baz"}}
        })

      assert %{"message" => _, "reason" => "unauthenticated"} = json_response(conn, 401)
    end

    test "Should update the doc", %{
      conn: conn,
      token: token,
      doc_id: _doc_id,
      mongo_pid: mongo_pid
    } do
      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
        |> post(Routes.docs_path(conn, :update_many, @coll), %{
          filter: %{"foo" => "bar"},
          update: %{"$set" => %{"foo" => "baz"}}
        })

      assert %{} = json_response(conn, 200)

      assert [%{"foo" => "baz"}] = Mongo.find(mongo_pid, @coll, %{}) |> Enum.to_list()
    end
  end

  describe "ApplicationRunner.DocsController.delete" do
    test "should be protected with a token", %{conn: conn, doc_id: doc_id} do
      conn = delete(conn, Routes.docs_path(conn, :delete, @coll, doc_id))

      assert %{"message" => _, "reason" => "unauthenticated"} = json_response(conn, 401)
    end

    test "Should delete the doc", %{
      conn: conn,
      token: token,
      doc_id: doc_id,
      mongo_pid: mongo_pid
    } do
      conn =
        conn
        |> Plug.Conn.put_req_header("authorization", "Bearer " <> token)
        |> delete(Routes.docs_path(conn, :delete, @coll, doc_id))

      assert %{} = json_response(conn, 200)

      assert [] = Mongo.find(mongo_pid, @coll, %{}) |> Enum.to_list()
    end
  end
end
