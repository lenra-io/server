defmodule ApplicationRunner.MongoStorageTest do
  use ApplicationRunner.ConnCase, async: false

  alias ApplicationRunner.Environment.MongoInstance
  alias ApplicationRunner.MongoStorage

  defp setup_mongo(env_id, coll) do
    Mongo.start_link(MongoInstance.config(env_id))
    MongoStorage.delete_coll(env_id, coll)
  end

  describe "start_transaction" do
    test "should return session_uuid" do
      setup_mongo(1, "test")
      assert {:ok, _uuid} = MongoStorage.start_transaction(1)
    end

    test "should return error if mongo not started" do
      env_id = Ecto.UUID.generate()

      assert {:noproc,
              {GenServer, :call,
               [
                 {:via, :swarm, {ApplicationRunner.Environment.MongoInstance, ^env_id}},
                 _any,
                 _timeout
               ]}} = catch_exit(MongoStorage.start_transaction(env_id))
    end
  end

  describe "create_doc" do
    test "create doc should create doc if transaction accepted" do
      env_id = Ecto.UUID.generate()

      setup_mongo(env_id, "test")
      assert {:ok, uuid} = MongoStorage.start_transaction(env_id)

      assert {:ok, _doc} = MongoStorage.create_doc(env_id, "test", %{test: "test"}, uuid)

      assert :ok = MongoStorage.commit_transaction(uuid, env_id)

      {:ok, docs} = MongoStorage.fetch_all_docs(env_id, "test")

      assert length(docs) == 1

      assert Enum.at(docs, 0)["test"] == "test"
    end

    test "create doc should return error if uuid is incorrect" do
      env_id = Ecto.UUID.generate()

      setup_mongo(env_id, "test")
      assert {:ok, _uuid} = MongoStorage.start_transaction(env_id)

      assert :badarg = catch_error(MongoStorage.create_doc(env_id, "test", %{test: "test"}, -1))
    end
  end

  describe "update_doc" do
    test "should add update" do
      env_id = Ecto.UUID.generate()

      setup_mongo(env_id, "test")
      assert {:ok, uuid} = MongoStorage.start_transaction(env_id)

      {:ok, %{"_id" => doc_id}} = MongoStorage.create_doc(env_id, "test", %{test: "test"})

      assert {:ok, _updated_doc} =
               MongoStorage.update_doc(
                 env_id,
                 "test",
                 Jason.encode!(doc_id) |> Jason.decode!(),
                 %{
                   test: "test2"
                 },
                 uuid
               )

      assert :ok = MongoStorage.commit_transaction(uuid, env_id)

      {:ok, docs} = MongoStorage.fetch_all_docs(env_id, "test")

      assert length(docs) == 1

      assert Enum.at(docs, 0)["test"] == "test2"
    end
  end

  describe "update_many" do
    test "should update" do
      env_id = Ecto.UUID.generate()

      setup_mongo(env_id, "test")

      {:ok, %{"_id" => _doc_id}} = MongoStorage.create_doc(env_id, "test", %{test: "test"})

      assert {:ok, _updated_doc} =
               MongoStorage.update_many(
                 env_id,
                 "test",
                 %{test: "test"},
                 %{
                   "$set" => %{"test" => "test2"}
                 }
               )

      {:ok, docs} = MongoStorage.fetch_all_docs(env_id, "test")

      assert length(docs) == 1

      assert Enum.at(docs, 0)["test"] == "test2"
    end

    test "should update many" do
      env_id = Ecto.UUID.generate()

      setup_mongo(env_id, "test")

      {:ok, %{"_id" => _doc_id}} = MongoStorage.create_doc(env_id, "test", %{test: "test"})
      {:ok, %{"_id" => _doc_id}} = MongoStorage.create_doc(env_id, "test", %{test: "test"})

      assert {:ok, _updated_doc} =
               MongoStorage.update_many(
                 env_id,
                 "test",
                 %{test: "test"},
                 %{
                   "$set" => %{"test" => "test2"}
                 }
               )

      {:ok, docs} = MongoStorage.fetch_all_docs(env_id, "test")

      assert length(docs) == 2

      assert Enum.at(docs, 0)["test"] == "test2"
      assert Enum.at(docs, 1)["test"] == "test2"
    end
  end

  describe "delete_doc" do
    test "should add delete" do
      env_id = Ecto.UUID.generate()

      setup_mongo(env_id, "test")
      assert {:ok, uuid} = MongoStorage.start_transaction(env_id)

      {:ok, %{"_id" => doc_id}} = MongoStorage.create_doc(env_id, "test", %{test: "test"})

      assert :ok =
               MongoStorage.delete_doc(1, "test", Jason.encode!(doc_id) |> Jason.decode!(), uuid)

      assert :ok = MongoStorage.commit_transaction(uuid, env_id)

      {:ok, docs} = MongoStorage.fetch_all_docs(env_id, "test")

      assert Enum.empty?(docs)
    end
  end

  describe "revert_transaction" do
    test "should revert update" do
      env_id = Ecto.UUID.generate()

      setup_mongo(env_id, "test")
      assert {:ok, uuid} = MongoStorage.start_transaction(env_id)

      {:ok, %{"_id" => doc_id}} = MongoStorage.create_doc(env_id, "test", %{test: "test"})

      assert {:ok, _updated_doc} =
               MongoStorage.update_doc(
                 env_id,
                 "test",
                 Jason.encode!(doc_id) |> Jason.decode!(),
                 %{
                   test: "test2"
                 },
                 uuid
               )

      assert :ok = MongoStorage.revert_transaction(uuid, env_id)

      {:ok, docs} = MongoStorage.fetch_all_docs(env_id, "test")

      assert length(docs) == 1

      assert Enum.at(docs, 0)["test"] == "test"
    end
  end
end
