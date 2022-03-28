defmodule Lenra.DataServicesTest do
  @moduledoc """
    Test the datastore services
  """
  use Lenra.RepoCase, async: true

  import Ecto.Query, only: [from: 2]

  alias ApplicationRunner.{Data, DataReferences, Datastore, DatastoreServices, UserData}
  alias Lenra.{DataServices, Environment, LenraApplication, LenraApplicationServices, Repo}

  setup do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    LenraApplicationServices.create(user.id, %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    })

    env = Repo.get_by(Environment, application_id: Enum.at(Repo.all(LenraApplication), 0).id)
    {:ok, env_id: env.id, user_id: user.id}
  end

  describe "DataServices.create_1/1" do
    test "should create data if json valid", %{env_id: env_id, user_id: user_id} do
      {:ok, inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))

      {:ok, %{inserted_data: inserted_data}} =
        DataServices.create(env_id, %{"datastore" => "users", "data" => %{"name" => "toto"}})

      data = Repo.get(Data, inserted_data.id)

      assert data.datastore_id == inserted_datastore.id
      assert data.data == %{"name" => "toto"}
    end

    test "should return error if json invalid", %{env_id: env_id, user_id: user_id} do
      Repo.insert(Datastore.new(env_id, %{"name" => "users"}))

      assert {:error, :data, :json_format_invalid, _changes_so_far} =
               DataServices.create(env_id, %{
                 "datastore" => "users",
                 "test" => %{"name" => "toto"}
               })
    end

    test "should return error if env_id invalid", %{env_id: env_id, user_id: user_id} do
      Repo.insert(Datastore.new(env_id, %{"name" => "users"}))

      assert {:error, :datastore, :datastore_not_found, _changes_so_far} =
               DataServices.create(-1, %{
                 "datastore" => "users",
                 "data" => %{"name" => "toto"}
               })
    end

    test "should return error if datastore name invalid", %{env_id: env_id, user_id: user_id} do
      assert {:error, :datastore, :datastore_not_found, _changes_so_far} =
               DataServices.create(env_id, %{
                 "datastore" => "test",
                 "data" => %{"name" => "toto"}
               })
    end

    test "should create reference if refs id is valid", %{env_id: env_id, user_id: user_id} do
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "points"}))

      {:ok, %{inserted_data: inserted_point}} =
        DataServices.create(env_id, %{
          "datastore" => "points",
          "data" => %{"score" => "10"}
        })

      {:ok, %{inserted_data: inserted_data}} =
        DataServices.create(env_id, %{
          "datastore" => "users",
          "data" => %{"name" => "toto"},
          "refs" => [inserted_point.id]
        })

      assert !is_nil(Repo.get_by(DataReferences, refs_id: inserted_point.id, refBy_id: inserted_data.id))
    end

    test "should create 2 if give 2 refs_id", %{env_id: env_id, user_id: user_id} do
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "points"}))

      {:ok, %{inserted_data: inserted_point}} =
        DataServices.create(env_id, %{
          "datastore" => "points",
          "data" => %{"score" => "10"}
        })

      {:ok, %{inserted_data: inserted_point_bis}} =
        DataServices.create(env_id, %{
          "datastore" => "points",
          "data" => %{"score" => "12"}
        })

      {:ok, %{inserted_data: inserted_data}} =
        DataServices.create(env_id, %{
          "datastore" => "users",
          "data" => %{"name" => "toto"},
          "refs" => [inserted_point.id, inserted_point_bis.id]
        })

      assert !is_nil(Repo.get_by(DataReferences, refs_id: inserted_point.id, refBy_id: inserted_data.id))

      assert !is_nil(
               Repo.get_by(DataReferences,
                 refs_id: inserted_point_bis.id,
                 refBy_id: inserted_data.id
               )
             )
    end

    test "should create reference if refBy id is valid", %{env_id: env_id, user_id: user_id} do
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "points"}))

      {:ok, %{inserted_data: inserted_user}} =
        DataServices.create(env_id, %{"datastore" => "users", "data" => %{"name" => "toto"}})

      {:ok, %{inserted_data: inserted_data}} =
        DataServices.create(env_id, %{
          "datastore" => "points",
          "data" => %{"score" => "10"},
          "refBy" => [inserted_user.id]
        })

      assert !is_nil(Repo.get_by(DataReferences, refs_id: inserted_data.id, refBy_id: inserted_user.id))
    end

    test "should create reference if refs and refBy id is valid", %{env_id: env_id, user_id: user_id} do
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "team"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "points"}))

      {:ok, %{inserted_data: inserted_team}} =
        DataServices.create(env_id, %{"datastore" => "team", "data" => %{"name" => "test"}})

      {:ok, %{inserted_data: inserted_point}} =
        DataServices.create(env_id, %{
          "datastore" => "points",
          "data" => %{"scrore" => "10"}
        })

      {:ok, %{inserted_data: inserted_user}} =
        DataServices.create(env_id, %{
          "datastore" => "users",
          "data" => %{"name" => "toto"},
          "refs" => [inserted_point.id],
          "refBy" => [inserted_team.id]
        })

      assert !is_nil(Repo.get_by(DataReferences, refs_id: inserted_user.id, refBy_id: inserted_team.id))

      assert !is_nil(Repo.get_by(DataReferences, refs_id: inserted_point.id, refBy_id: inserted_user.id))
    end

    test "should return error if refs id invalid ", %{env_id: env_id, user_id: user_id} do
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "points"}))

      assert {:error, :"inserted_refs_-1", %{errors: [refs_id: {"does not exist", _constraint}]}, _change_so_far} =
               DataServices.create(env_id, %{
                 "datastore" => "users",
                 "data" => %{"name" => "toto"},
                 "refs" => [-1]
               })
    end

    test "should return error if refBy_id invalid", %{env_id: env_id, user_id: user_id} do
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "points"}))

      assert {:error, :"inserted_refBy_-1", %{errors: [refBy_id: {"does not exist", _constraint}]}, _change_so_far} =
               DataServices.create(env_id, %{
                 "datastore" => "points",
                 "data" => %{"score" => "10"},
                 "refBy" => [-1]
               })
    end
  end

  describe "Lenra.DataServices.get_old_data_1/1" do
    test "should return last data", %{env_id: env_id, user_id: user_id} do
      env_id
      |> DatastoreServices.create(%{"name" => "UserDatas"})
      |> Repo.transaction()

      DataServices.create_and_link(user_id, env_id, %{"datastore" => "UserDatas", "data" => %{"test" => "test"}})

      assert %{"test" => "test"} = DataServices.get_old_data(user_id, env_id).data
    end
  end

  describe "DataServices.delete_1/1" do
    test "should delete data if json valid", %{env_id: env_id, user_id: user_id} do
      Repo.insert(Datastore.new(env_id, %{"name" => "users"}))

      {:ok, %{inserted_data: inserted_data}} =
        DataServices.create(env_id, %{"datastore" => "users", "data" => %{"name" => "toto"}})

      data = Repo.get(Data, inserted_data.id)

      DataServices.delete(data.id)

      deleted_data = Repo.get(Data, inserted_data.id)

      assert deleted_data == nil
    end

    test "should return error id invalid", %{env_id: _env_id, user_id: _user_id} do
      assert {:error, :data, :data_not_found, _changes_so_far} = DataServices.delete(-1)
    end
  end

  describe "DataServices.update_1/1" do
    test "should update data if json valid", %{env_id: env_id, user_id: user_id} do
      Repo.insert(Datastore.new(env_id, %{"name" => "users"}))

      {:ok, %{inserted_data: inserted_data}} =
        DataServices.create(env_id, %{"datastore" => "users", "data" => %{"name" => "toto"}})

      data = Repo.get(Data, inserted_data.id)

      DataServices.update(data.id, %{"data" => %{"name" => "test"}})

      updated_data = Repo.get(Data, inserted_data.id)

      assert updated_data.data == %{"name" => "test"}
    end

    test "should return error id invalid", %{env_id: _env_id} do
      assert {:error, :data, :data_not_found, _changes_so_far} = DataServices.update(-1, %{"data" => %{}})
    end

    test "should also update refs on update", %{env_id: env_id, user_id: user_id} do
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "points"}))

      {:ok, %{inserted_data: inserted_point}} =
        DataServices.create(env_id, %{
          "datastore" => "points",
          "data" => %{"score" => "10"}
        })

      {:ok, %{inserted_data: inserted_point_bis}} =
        DataServices.create(env_id, %{
          "datastore" => "points",
          "data" => %{"score" => "12"}
        })

      {:ok, %{inserted_data: inserted_data}} =
        DataServices.create(env_id, %{
          "datastore" => "users",
          "data" => %{"name" => "toto"},
          "refs" => [inserted_point.id]
        })

      {:ok, %{data: updated_data}} =
        DataServices.update(inserted_data.id, %{
          "refs" => [inserted_point_bis.id]
        })

      data =
        Data
        |> Repo.get(updated_data.id)
        |> Repo.preload(:refs)

      assert 1 == length(data.refs)

      assert List.first(data.refs).id ==
               inserted_point_bis.id
    end

    test "should also update refBy on update", %{env_id: env_id, user_id: user_id} do
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "points"}))

      {:ok, %{inserted_data: inserted_data}} =
        DataServices.create(env_id, %{
          "datastore" => "users",
          "data" => %{"name" => "toto"}
        })

      {:ok, %{inserted_data: inserted_data_bis}} =
        DataServices.create(env_id, %{
          "datastore" => "users",
          "data" => %{"name" => "test"}
        })

      {:ok, %{inserted_data: inserted_point}} =
        DataServices.create(env_id, %{
          "datastore" => "points",
          "data" => %{"score" => "10"},
          "refBy" => [inserted_data.id]
        })

      {:ok, %{data: updated_data}} =
        DataServices.update(inserted_point.id, %{
          "refBy" => [inserted_data_bis.id]
        })

      data =
        Data
        |> Repo.get(updated_data.id)
        |> Repo.preload(:refBy)

      assert 1 == length(data.refBy)

      assert List.first(data.refBy).id ==
               inserted_data_bis.id
    end

    test "should also update refs and refBy on update", %{env_id: env_id, user_id: user_id} do
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "team"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "points"}))

      {:ok, %{inserted_data: inserted_team}} =
        DataServices.create(env_id, %{
          "datastore" => "team",
          "data" => %{"name" => "team1"}
        })

      {:ok, %{inserted_data: inserted_team_bis}} =
        DataServices.create(env_id, %{
          "datastore" => "team",
          "data" => %{"name" => "team2"}
        })

      {:ok, %{inserted_data: inserted_point}} =
        DataServices.create(env_id, %{
          "datastore" => "points",
          "data" => %{"name" => "10"}
        })

      {:ok, %{inserted_data: inserted_point_bis}} =
        DataServices.create(env_id, %{
          "datastore" => "points",
          "data" => %{"name" => "12"}
        })

      {:ok, %{inserted_data: inserted_user}} =
        DataServices.create(env_id, %{
          "datastore" => "users",
          "data" => %{"name" => "toto"},
          "refs" => [inserted_point.id],
          "refBy" => [inserted_team.id]
        })

      {:ok, %{data: updated_data}} =
        DataServices.update(inserted_user.id, %{
          "refs" => [inserted_point_bis.id],
          "refBy" => [inserted_team_bis.id]
        })

      data =
        Data
        |> Repo.get(updated_data.id)
        |> Repo.preload(:refBy)
        |> Repo.preload(:refs)

      assert 1 == length(data.refBy)

      assert List.first(data.refBy).id ==
               inserted_team_bis.id

      assert 1 == length(data.refs)

      assert List.first(data.refs).id ==
               inserted_point_bis.id
    end

    test "should return error if update with invalid refs id", %{env_id: env_id, user_id: user_id} do
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "points"}))

      {:ok, %{inserted_data: inserted_point}} =
        DataServices.create(env_id, %{
          "datastore" => "points",
          "data" => %{"name" => "10"}
        })

      {:ok, %{inserted_data: inserted_user}} =
        DataServices.create(env_id, %{
          "datastore" => "users",
          "data" => %{"name" => "toto"},
          "refs" => [inserted_point.id]
        })

      {:error, :refs, :references_not_found, _change_so_far} =
        DataServices.update(inserted_user.id, %{
          "refs" => [-1]
        })
    end

    test "should return error if update with invalid ref_by id", %{env_id: env_id, user_id: user_id} do
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "team"}))
      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))

      {:ok, %{inserted_data: inserted_team}} =
        DataServices.create(env_id, %{
          "datastore" => "team",
          "data" => %{"name" => "team1"}
        })

      {:ok, %{inserted_data: inserted_user}} =
        DataServices.create(env_id, %{
          "datastore" => "users",
          "data" => %{"name" => "toto"},
          "refBy" => [inserted_team.id]
        })

      {:error, :refBy, :references_not_found, _change_so_far} =
        DataServices.update(inserted_user.id, %{
          "refBy" => [-1]
        })
    end

    test "should not update data if env_id not the same", %{env_id: env_id, user_id: user_id} do
      {:ok, %{inserted_env: environment}} =
        LenraApplicationServices.create(user_id, %{
          name: "test-update",
          color: "FFFFFF",
          icon: "60189"
        })

      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "team"}))

      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(environment.id, %{"name" => "team2"}))

      {:ok, _inserted_datastore} = Repo.insert(Datastore.new(env_id, %{"name" => "users"}))

      {:ok, %{inserted_data: inserted_team}} =
        DataServices.create(env_id, %{
          "datastore" => "team",
          "data" => %{"name" => "team1"}
        })

      {:ok, %{inserted_data: inserted_team_bis}} =
        DataServices.create(environment.id, %{
          "datastore" => "team2",
          "data" => %{"name" => "team2"}
        })

      {:ok, %{inserted_data: inserted_user}} =
        DataServices.create(env_id, %{
          "datastore" => "users",
          "data" => %{"name" => "toto"},
          "refBy" => [inserted_team.id]
        })

      {:error, :refBy, :references_not_found, _change_so_far} =
        DataServices.update(inserted_user.id, %{
          "refBy" => [inserted_team_bis.id]
        })
    end
  end

  describe "Lenra.DataServices.upsert_data_1/1" do
    test "should update last data if data exist", %{env_id: env_id, user_id: user_id} do
      env_id
      |> DatastoreServices.create(%{"name" => "UserDatas"})
      |> Repo.transaction()

      DataServices.create_and_link(user_id, env_id, %{"datastore" => "UserDatas", "data" => %{"test" => "test"}})

      DataServices.upsert_data(user_id, env_id, %{"datastore" => "UserDatas", "data" => %{"test" => "test2"}})

      assert %{"test" => "test2"} = DataServices.get_old_data(user_id, env_id).data
    end

    test "should create data if data not exist", %{env_id: env_id, user_id: user_id} do
      env_id
      |> DatastoreServices.create(%{"name" => "UserDatas"})
      |> Repo.transaction()

      DataServices.upsert_data(user_id, env_id, %{"datastore" => "UserDatas", "data" => %{"test" => "test"}})

      assert %{"test" => "test"} = DataServices.get_old_data(user_id, env_id).data
    end
  end

  describe "Lenra.DataServices.create_and_link_1/1" do
    test "should create data and user_data", %{env_id: env_id, user_id: user_id} do
      env_id
      |> DatastoreServices.create(%{"name" => "UserDatas"})
      |> Repo.transaction()

      DataServices.create_and_link(user_id, env_id, %{"datastore" => "UserDatas", "data" => %{"test" => "test"}})

      %{user_id: user_data_user_id, data_id: user_data_data_id} =
        Repo.one(
          from(u in UserData,
            join: d in Data,
            on: d.id == u.data_id,
            join: ds in Datastore,
            on: ds.id == d.datastore_id,
            where: u.user_id == ^user_id and ds.environment_id == ^env_id and ds.name == "UserDatas",
            select: u
          )
        )

      old_data = DataServices.get_old_data(user_id, env_id)

      assert %{"test" => "test"} = old_data.data
      assert user_data_data_id == old_data.id
      assert user_data_user_id == user_id
    end
  end
end
