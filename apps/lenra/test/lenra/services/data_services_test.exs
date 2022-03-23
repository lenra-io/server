defmodule Lenra.DataServicesTest do
  @moduledoc """
    Test the datastore services
  """
  use Lenra.RepoCase, async: true

  import Ecto.Query, only: [from: 2]

  alias ApplicationRunner.{DatastoreServices, UserData, Data, Datastore}
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

  describe "Lenra.DataServices.get_old_data_1/1" do
    test "should return last data", %{env_id: env_id, user_id: user_id} do
      env_id
      |> DatastoreServices.create(%{"name" => "UserDatas"})
      |> Repo.transaction()

      DataServices.create_and_link(user_id, env_id, %{"datastore" => "UserDatas", "data" => %{"test" => "test"}})

      assert %{"test" => "test"} = DataServices.get_old_data(user_id, env_id).data
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
