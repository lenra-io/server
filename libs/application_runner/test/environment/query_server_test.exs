defmodule ApplicationRunner.Environment.QueryServerTest do
  use ExUnit.Case

  alias ApplicationRunner.Environment.{
    MongoInstance,
    QueryDynSup,
    QueryServer,
    ViewServer
  }

  alias QueryParser.Parser

  @env_id 1337

  def insert_event(idx, coll \\ "test", id \\ nil, time \\ Mongo.timestamp(DateTime.utc_now())) do
    id = if id == nil, do: idx, else: id

    %{
      "_id" => id,
      "clusterTime" => time,
      "operationType" => "insert",
      "ns" => %{
        "coll" => coll
      },
      "documentKey" => %{
        "_id" => "#{idx}"
      },
      "fullDocument" => %{
        "_id" => "#{idx}",
        "name" => "test#{idx}",
        "idx" => idx
      }
    }
  end

  def update_event(idx, coll \\ "test", id \\ nil, time \\ Mongo.timestamp(DateTime.utc_now())) do
    id = if id == nil, do: idx, else: id

    %{
      "_id" => id,
      "clusterTime" => time,
      "operationType" => "update",
      "ns" => %{
        "coll" => coll
      },
      "documentKey" => %{
        "_id" => "#{idx}"
      },
      "fullDocument" => %{
        "_id" => "#{idx}",
        "name" => "new_test#{idx}",
        "foo" => "bar"
      }
    }
  end

  def replace_event(idx, coll \\ "test", id \\ nil, time \\ Mongo.timestamp(DateTime.utc_now())) do
    id = if id == nil, do: idx, else: id

    %{
      "_id" => id,
      "clusterTime" => time,
      "operationType" => "replace",
      "ns" => %{
        "coll" => coll
      },
      "documentKey" => %{
        "_id" => "#{idx}"
      },
      "fullDocument" => %{
        "_id" => "#{idx}",
        "name" => "new_test#{idx}",
        "foo" => "bar"
      }
    }
  end

  def delete_event(idx, coll \\ "test", id \\ nil, time \\ Mongo.timestamp(DateTime.utc_now())) do
    id = if id == nil, do: idx, else: id

    %{
      "_id" => id,
      "clusterTime" => time,
      "operationType" => "delete",
      "ns" => %{
        "coll" => coll
      },
      "documentKey" => %{
        "_id" => "#{idx}"
      }
    }
  end

  def drop_event(coll, id \\ 1, time \\ Mongo.timestamp(DateTime.utc_now())) do
    %{
      "_id" => id,
      "clusterTime" => time,
      "operationType" => "drop",
      "ns" => %{
        "coll" => coll
      }
    }
  end

  def rename_event(from, to, id \\ 1, time \\ Mongo.timestamp(DateTime.utc_now())) do
    %{
      "_id" => id,
      "clusterTime" => time,
      "operationType" => "rename",
      "ns" => %{
        "coll" => from
      },
      "to" => %{
        "coll" => to
      }
    }
  end

  def loop(name, pid) do
    receive do
      msg ->
        send(pid, {name, msg})
        loop(name, pid)
    end
  end

  def spawn_pass_process(name) do
    pid = spawn(__MODULE__, :loop, [name, self()])
    Swarm.register_name({:test_pass_process, name}, pid)
    pid
  end

  setup do
    {:ok, _} = start_supervised({QueryDynSup, env_id: @env_id})

    # TODO : create a mongo module and use it to create a new mongo connexion.

    mongo_name = MongoInstance.get_full_name(@env_id)

    {:ok, _} =
      start_supervised({
        Mongo,
        MongoInstance.config(@env_id)
      })

    start_supervised(
      {Task.Supervisor,
       name:
         {:via, :swarm,
          {ApplicationRunner.Environment.MongoInstance.TaskSupervisor,
           MongoInstance.get_name(@env_id)}}}
    )

    Mongo.drop_collection(mongo_name, "test")

    # Register self in swarm to allow grouping
    :yes = Swarm.register_name(:test_process, self())

    # Swarm seems to be a bit too slow to remove a registered name when a genserver stop leading to
    # QueryDynSup acting as already started on some random test.
    # To prevent this, i make sure to unregister every added supervised server

    on_exit(fn ->
      Swarm.unregister_name(:test_process)
      Swarm.unregister_name(QueryDynSup.get_name(@env_id))
      Swarm.unregister_name(MongoInstance.get_name(@env_id))

      Swarm.unregister_name(
        {ApplicationRunner.Environment.MongoInstance.TaskSupervisor,
         MongoInstance.get_name(@env_id)}
      )
    end)

    {:ok, %{mongo_name: mongo_name}}
  end

  describe "QueryServer setup" do
    test "should start with coll and query in the correct swarm group" do
      assert [] = Swarm.members(QueryServer.group_name("42"))

      assert {:ok, pid} =
               QueryDynSup.ensure_child_started(
                 @env_id,
                 "test",
                 Parser.parse!("{}"),
                 Parser.replace_params(%{}, %{}),
                 %{}
               )

      QueryServer.join_group(pid, "42")
      assert [_pid] = Swarm.members(QueryServer.group_name("42"))
    end

    test "should have the correct state" do
      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      assert %{
               coll: "test",
               query_parsed: %{"clauses" => [], "pos" => "expression"},
               data: []
             } = :sys.get_state(QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")}))
    end

    test "should get the correct data from the mongo db", %{mongo_name: mongo_name} do
      data = [
        %{"name" => "test1", "idx" => 1},
        %{"name" => "test2", "idx" => 2},
        %{"name" => "test3", "idx" => 3}
      ]

      Mongo.insert_many!(mongo_name, "test", data)

      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          %{},
          %{}
        )

      assert %{
               coll: "test",
               data: [
                 %{"name" => "test1", "idx" => 1, "_id" => _},
                 %{"name" => "test2", "idx" => 2, "_id" => _},
                 %{"name" => "test3", "idx" => 3, "_id" => _}
               ]
             } = :sys.get_state(QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")}))
    end

    test "should return :ok for the {:mongo_event, event} call" do
      {:ok, pid} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      assert :ok = GenServer.call(pid, {:mongo_event, insert_event(1)})
    end

    test "should be able to called a group using Swarm.multi_call" do
      {:ok, pid1} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          %{},
          %{}
        )

      {:ok, ^pid1} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          %{},
          %{}
        )

      {:ok, pid2} =
        QueryDynSup.ensure_child_started(@env_id, "foo", Parser.parse!("{}"), %{}, %{})

      QueryServer.join_group(pid1, "42")
      QueryServer.join_group(pid1, "43")
      QueryServer.join_group(pid2, "43")

      assert [^pid1] = Swarm.members(QueryServer.group_name("42"))
      pids = Swarm.members(QueryServer.group_name("43"))
      assert pid1 in pids
      assert pid2 in pids
      # the two group share the same "test", "{}" server
      assert [:ok] =
               Swarm.multi_call(QueryServer.group_name("42"), {:mongo_event, insert_event(1)})

      assert [:ok, :ok] =
               Swarm.multi_call(QueryServer.group_name("43"), {:mongo_event, insert_event(1)})
    end

    test "should start once with the same coll/query" do
      assert {:ok, pid} =
               QueryDynSup.ensure_child_started(
                 @env_id,
                 "test",
                 Parser.parse!("{}"),
                 Parser.replace_params(%{}, %{}),
                 %{}
               )

      assert {:ok, ^pid} =
               QueryDynSup.ensure_child_started(
                 @env_id,
                 "test",
                 Parser.parse!("{}"),
                 Parser.replace_params(%{}, %{}),
                 %{}
               )
    end

    test "should be registered with a specific name" do
      assert {:ok, pid} =
               QueryDynSup.ensure_child_started(
                 @env_id,
                 "test",
                 Parser.parse!("{}"),
                 Parser.replace_params(%{}, %{}),
                 %{}
               )

      name = {QueryServer, {@env_id, "test", Parser.parse!("{}")}}
      assert ^name = QueryServer.get_name({@env_id, "test", Parser.parse!("{}")})
      assert ^pid = Swarm.whereis_name(name)
    end

    test "should start monitoring process if asked to" do
      assert {:ok, qs_pid} =
               QueryDynSup.ensure_child_started(
                 @env_id,
                 "test",
                 Parser.parse!("{}"),
                 Parser.replace_params(%{}, %{}),
                 %{}
               )

      pid1 =
        spawn(fn ->
          receive do
            :stop -> :ok
          end
        end)

      pid2 =
        spawn(fn ->
          receive do
            :stop -> :ok
          end
        end)

      QueryServer.monitor(qs_pid, pid1)
      QueryServer.monitor(qs_pid, pid2)
      assert {:monitors, [{:process, pid1}, {:process, pid2}]} == Process.info(qs_pid, :monitors)
      assert {:monitored_by, [qs_pid]} == Process.info(pid1, :monitored_by)
      assert {:monitored_by, [qs_pid]} == Process.info(pid2, :monitored_by)
      ms = MapSet.new([pid1, pid2])
      assert %{w_pids: ^ms} = :sys.get_state(qs_pid)
    end

    test "should quit if monitored process dies" do
      assert {:ok, qs_pid} =
               QueryDynSup.ensure_child_started(
                 @env_id,
                 "test",
                 Parser.parse!("{}"),
                 Parser.replace_params(%{}, %{}),
                 %{}
               )

      pid1 =
        spawn_link(fn ->
          receive do
            :stop -> :ok
          end
        end)

      pid2 =
        spawn_link(fn ->
          receive do
            :stop -> :ok
          end
        end)

      QueryServer.monitor(qs_pid, pid1)
      QueryServer.monitor(qs_pid, pid2)

      assert Process.alive?(qs_pid)
      send(pid1, :stop)
      assert Process.alive?(qs_pid)
      send(pid2, :stop)
      # Wait a bit to let the genserver the time to stop
      :timer.sleep(100)
      assert not Process.alive?(qs_pid)
    end

    test "should get have one query server and send filtered data for projection", %{
      mongo_name: mongo_name
    } do
      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          %{},
          %{"name" => true}
        )

      # View server with no projection
      Swarm.join(ViewServer.group_name(@env_id, "test", Parser.parse!("{}"), %{}), self())

      # View server with projection
      Swarm.join(
        ViewServer.group_name(@env_id, "test", Parser.parse!("{}"), %{"name" => true}),
        self()
      )

      timestamp = Mongo.timestamp(DateTime.utc_now())

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      GenServer.call(name, {:mongo_event, insert_event(1, "test", 1, timestamp)})

      # View server with projection received filtered data
      assert_received {:data_changed,
                       [
                         %{"name" => "test1"}
                       ]}

      # View server with no projection received all data
      assert_received {:data_changed,
                       [
                         %{"name" => "test1", "idx" => 1, "_id" => _}
                       ]}

      assert %{
               coll: "test",
               data: [
                 %{"name" => "test1", "idx" => 1, "_id" => _}
               ]
             } = :sys.get_state(QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")}))
    end
  end

  describe "QueryServer prevent handling duplicate event" do
    test "should reject two event with same id and timestamp" do
      assert {:ok, _} =
               QueryDynSup.ensure_child_started(
                 @env_id,
                 "test",
                 Parser.parse!("{}"),
                 Parser.replace_params(%{}, %{}),
                 %{}
               )

      timestamp = Mongo.timestamp(DateTime.utc_now())
      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      GenServer.call(name, {:mongo_event, insert_event(1, "test", 1, timestamp)})

      assert %{data: [%{"_id" => "1"}]} = :sys.get_state(name)

      GenServer.call(name, {:mongo_event, insert_event(2, "test", 1, timestamp)})

      assert %{data: [%{"_id" => "1"}]} = :sys.get_state(name)
    end

    test "should handle two event with same timestamp but different ids" do
      assert {:ok, _} =
               QueryDynSup.ensure_child_started(
                 @env_id,
                 "test",
                 Parser.parse!("{}"),
                 Parser.replace_params(%{}, %{}),
                 %{}
               )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})
      timestamp = Mongo.timestamp(DateTime.utc_now())

      GenServer.call(name, {:mongo_event, insert_event(1, "test", 1, timestamp)})
      assert %{data: [%{"_id" => "1"}]} = :sys.get_state(name)
      GenServer.call(name, {:mongo_event, insert_event(2, "test", 2, timestamp)})
      assert %{data: [%{"_id" => "1"}, %{"_id" => "2"}]} = :sys.get_state(name)
    end

    test "should handle N event incremental ids and timestamps" do
      assert {:ok, _} =
               QueryDynSup.ensure_child_started(
                 @env_id,
                 "test",
                 Parser.parse!("{}"),
                 Parser.replace_params(%{}, %{}),
                 %{}
               )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      # The Mongo timestamp is made with two values :
      # - The :value part is the number of seconds since epoch (second timestamp)
      # - The :ordinal part is an incremental value in case of multiple event in the same second.
      # We can simply increment the ordinal to create a new timestamp.
      timestamp_1 = Mongo.timestamp(DateTime.utc_now())
      timestamp_2 = Map.put(timestamp_1, :ordinal, 2)
      timestamp_3 = Map.put(timestamp_1, :ordinal, 3)

      GenServer.call(name, {:mongo_event, insert_event(1, "test", 1, timestamp_1)})
      assert %{data: [%{"_id" => "1"}]} = :sys.get_state(name)
      GenServer.call(name, {:mongo_event, insert_event(2, "test", 2, timestamp_2)})
      assert %{data: [%{"_id" => "1"}, %{"_id" => "2"}]} = :sys.get_state(name)
      GenServer.call(name, {:mongo_event, insert_event(3, "test", 3, timestamp_3)})
      assert %{data: [%{"_id" => "1"}, %{"_id" => "2"}, %{"_id" => "3"}]} = :sys.get_state(name)
    end

    test "should reject an event with older timestamp" do
      assert {:ok, _} =
               QueryDynSup.ensure_child_started(
                 @env_id,
                 "test",
                 Parser.parse!("{}"),
                 Parser.replace_params(%{}, %{}),
                 %{}
               )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})
      timestamp_1 = Mongo.timestamp(DateTime.utc_now())
      timestamp_2 = Map.put(timestamp_1, :ordinal, 2)
      timestamp_3 = Map.put(timestamp_1, :ordinal, 3)

      GenServer.call(name, {:mongo_event, insert_event(1, "test", 1, timestamp_1)})
      assert %{data: [%{"_id" => "1"}]} = :sys.get_state(name)
      GenServer.call(name, {:mongo_event, insert_event(2, "test", 2, timestamp_3)})
      assert %{data: [%{"_id" => "1"}, %{"_id" => "2"}]} = :sys.get_state(name)
      GenServer.call(name, {:mongo_event, insert_event(3, "test", 3, timestamp_2)})
      assert %{data: [%{"_id" => "1"}, %{"_id" => "2"}]} = :sys.get_state(name)
    end
  end

  describe "QueryServer insert" do
    test "should insert data for the correct coll" do
      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1)})
      assert :ok = GenServer.call(name, {:mongo_event, insert_event(2)})

      assert %{
               coll: "test",
               data: [
                 %{"_id" => "1", "idx" => 1, "name" => "test1"},
                 %{"_id" => "2", "idx" => 2, "name" => "test2"}
               ]
             } = :sys.get_state(name)
    end

    test "should notify data changed in the widget group correctly" do
      {:ok, pid1} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          %{},
          %{}
        )

      q2 = %{"idx" => 1}
      eq2 = Jason.encode!(q2)

      {:ok, pid2} =
        QueryDynSup.ensure_child_started(@env_id, "test", Parser.parse!(eq2), %{}, %{})

      QueryServer.join_group(pid1, "42")
      QueryServer.join_group(pid2, "42")

      # BOTH process in Group 1 should receive the change event
      group1 = ViewServer.group_name(@env_id, "test", Parser.parse!("{}"), %{})
      # Group 1 should NOT receive the change event (wrong env_id)
      group2 = ViewServer.group_name(@env_id + 1, "test", Parser.parse!("{}"), %{})
      # Group 1 should NOT receive the change event (wrong coll)
      group3 = ViewServer.group_name(@env_id, "test1", Parser.parse!("{}"), %{})
      # Group 1 should NOT receive the change event (query does not match)
      group4 = ViewServer.group_name(@env_id, "test", Parser.parse!("{\"aaaa\": 1}"), %{})
      # Group 1 should receive the change event (query match)
      group5 = ViewServer.group_name(@env_id, "test", Parser.parse!("{\"idx\": 1}"), %{})

      p1 = spawn_pass_process(:a1)
      p1b = spawn_pass_process(:a1b)
      p2 = spawn_pass_process(:a2)
      p3 = spawn_pass_process(:a3)
      p4 = spawn_pass_process(:a4)
      p5 = spawn_pass_process(:a5)

      Swarm.join(group1, p1)
      Swarm.join(group1, p1b)
      Swarm.join(group2, p2)
      Swarm.join(group3, p3)
      Swarm.join(group4, p4)
      Swarm.join(group5, p5)

      Swarm.multi_call(QueryServer.group_name("42"), {:mongo_event, insert_event(1)})

      assert_received {:a1, {:data_changed, [%{"_id" => "1"}]}}
      assert_received {:a1b, {:data_changed, [%{"_id" => "1"}]}}
      refute_received {:a2, _}
      refute_received {:a3, _}
      refute_received {:a4, _}
      assert_received {:a5, {:data_changed, [%{"_id" => "1"}]}}
    end

    test "should NOT insert data for the wrong coll" do
      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1)})
      assert :ok = GenServer.call(name, {:mongo_event, insert_event(2, "foo")})

      assert %{
               coll: "test",
               data: [%{"_id" => "1"}]
             } = :sys.get_state(name)
    end

    test "should NOT insert data if the query does not match the new element" do
      q = %{"idx" => %{"$lt" => 3}}
      eq = Jason.encode!(q)
      {:ok, _} = QueryDynSup.ensure_child_started(@env_id, "test", Parser.parse!(eq), q, %{})

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!(eq)})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1)})
      assert :ok = GenServer.call(name, {:mongo_event, insert_event(2)})
      assert :ok = GenServer.call(name, {:mongo_event, insert_event(3)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1"}, %{"_id" => "2"}]
             } = :sys.get_state(name)
    end
  end

  describe "QueryServer update" do
    test "should update an older data if doc _id is the same" do
      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1, "test", 1)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)

      assert :ok = GenServer.call(name, {:mongo_event, update_event(1, "test", 2)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "new_test1", "foo" => "bar"}]
             } = :sys.get_state(name)
    end

    test "should NOT update an older data if the coll is different" do
      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)

      assert :ok = GenServer.call(name, {:mongo_event, update_event(1, "foo")})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)
    end

    test "should remove the old data if _id is the same but query does not match anymore" do
      q = %{"name" => "test1"}
      eq = Jason.encode!(q)

      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!(eq),
          Parser.replace_params(q, %{}),
          %{}
        )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!(eq)})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1, "test", 1)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)

      assert :ok = GenServer.call(name, {:mongo_event, update_event(1, "test", 2)})

      assert %{
               coll: "test",
               data: []
             } = :sys.get_state(name)
    end
  end

  describe "QueryServer replace" do
    test "should replace an older data if _id is the same" do
      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1, "test", 1)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)

      assert :ok = GenServer.call(name, {:mongo_event, replace_event(1, "test", 2)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "new_test1", "foo" => "bar"}]
             } = :sys.get_state(name)
    end

    test "should NOT replace an older data if the coll is different" do
      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)

      assert :ok = GenServer.call(name, {:mongo_event, replace_event(1, "foo", 2)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)
    end

    test "should remove the old data if _id is the same but query does not match anymore" do
      q = %{"name" => "test1"}
      eq = Jason.encode!(q)

      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!(eq),
          q,
          %{}
        )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!(eq)})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1, "test", 1)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)

      assert :ok = GenServer.call(name, {:mongo_event, replace_event(1, "test", 2)})

      assert %{
               coll: "test",
               data: []
             } = :sys.get_state(name)
    end
  end

  describe "QueryServer delete" do
    test "should delete an older data if _id and coll is the same" do
      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1, "test", 1)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)

      assert :ok = GenServer.call(name, {:mongo_event, delete_event(1, "test", 2)})

      assert %{
               coll: "test",
               data: []
             } = :sys.get_state(name)
    end

    test "should NOT delete an older data if coll is different" do
      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1, "test", 1)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)

      assert :ok = GenServer.call(name, {:mongo_event, delete_event(1, "foo", 2)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)
    end

    test "should NOT delete an older data if id is different" do
      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1, "test", 1)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)

      assert :ok = GenServer.call(name, {:mongo_event, delete_event(2, "test", 2)})

      assert %{
               coll: "test",
               data: [%{"_id" => "1", "name" => "test1"}]
             } = :sys.get_state(name)
    end
  end

  describe "QueryServer drop coll" do
    test "should stop the genserver when drop the coll" do
      {:ok, pid} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      assert Process.alive?(pid)
      assert :ok = GenServer.call(pid, {:mongo_event, drop_event("test")})
      assert not Process.alive?(pid)
    end

    test "should NOT stop the genserver when drop another coll" do
      {:ok, pid} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      assert Process.alive?(pid)
      assert :ok = GenServer.call(pid, {:mongo_event, drop_event("foo")})
      assert Process.alive?(pid)
    end
  end

  describe "QueryServer rename coll" do
    test "should rename the coll and still work under a new name" do
      {:ok, pid} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      name = QueryServer.get_name({@env_id, "test", Parser.parse!("{}")})
      new_name = QueryServer.get_name({@env_id, "bar", Parser.parse!("{}")})

      group = ViewServer.group_name(@env_id, "test", Parser.parse!("{}"), %{})
      new_group = ViewServer.group_name(@env_id, "bar", Parser.parse!("{}"), %{})
      p1 = spawn_pass_process(:p1)
      p2 = spawn_pass_process(:p2)
      Swarm.join(group, p1)
      Swarm.join(new_group, p2)

      timestamp_1 = Mongo.timestamp(DateTime.utc_now())
      timestamp_2 = Map.put(timestamp_1, :ordinal, 2)
      timestamp_3 = Map.put(timestamp_1, :ordinal, 3)

      # Register under the correct name, insert is working as expected.
      :ok = GenServer.call(pid, {:mongo_event, insert_event(1, "test", 1, timestamp_1)})
      assert ^pid = Swarm.whereis_name(name)
      assert_receive {:p1, {:data_changed, [%{"_id" => "1"}]}}

      # Rename the coll, the server should still work the same.
      :ok = GenServer.call(pid, {:mongo_event, rename_event("test", "bar", 2, timestamp_2)})
      assert :undefined = Swarm.whereis_name(name)
      assert ^pid = Swarm.whereis_name(new_name)
      assert_receive {:p1, {:coll_changed, "bar"}}

      # The notification is sent to the new group
      :ok = GenServer.call(pid, {:mongo_event, insert_event(2, "bar", 3, timestamp_3)})
      assert_receive {:p2, {:data_changed, [%{"_id" => "1"}, %{"_id" => "2"}]}}
    end

    test "should ignore the rename if namesapce coll is different" do
      {:ok, _} =
        QueryDynSup.ensure_child_started(
          @env_id,
          "test",
          Parser.parse!("{}"),
          Parser.replace_params(%{}, %{}),
          %{}
        )

      name = QueryServer.get_full_name({@env_id, "test", Parser.parse!("{}")})

      assert :ok = GenServer.call(name, {:mongo_event, insert_event(1)})
      assert %{coll: "test", data: [%{"_id" => "1"}]} = :sys.get_state(name)

      assert :ok = GenServer.call(name, {:mongo_event, rename_event("foo", "bar")})
      assert :ok = GenServer.call(name, {:mongo_event, insert_event(2)})
      assert :ok = GenServer.call(name, {:mongo_event, insert_event(3, "bar")})

      assert %{coll: "test", data: [%{"_id" => "1"}, %{"_id" => "2"}]} = :sys.get_state(name)
    end
  end
end
