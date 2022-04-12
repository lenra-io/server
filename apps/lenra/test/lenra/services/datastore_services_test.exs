defmodule Lenra.DatastoreServicesTest do
  @moduledoc """
    Test the datastore services
  """
  use Lenra.RepoCase, async: true

  alias ApplicationRunner.{Data, Datastore}
  alias Lenra.{DatastoreServices, Environment, LenraApplication, LenraApplicationServices, Repo}

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

  describe "DatastoreServices.create_1/1" do
    test "should create datastore if params valid", %{env_id: env_id, user_id: _user_id} do
      {:ok, %{inserted_datastore: inserted_datastore}} = DatastoreServices.create(env_id, %{"name" => "users"})

      datastore = Repo.get(Datastore, inserted_datastore.id)

      assert datastore.id == inserted_datastore.id
      assert datastore.name == "users"
    end

    test "should return error if datastore same name and same env_id", %{env_id: env_id, user_id: _user_id} do
      assert {:ok, %{inserted_datastore: _inserted_datastore}} = DatastoreServices.create(env_id, %{"name" => "users"})

      assert {:error, :inserted_datastore, %{errors: [name: {"has already been taken", _constraint}]}, _changes_so_far} =
               DatastoreServices.create(env_id, %{"name" => "users"})
    end

    test "should create datastore if datastore same name but different env_id", %{env_id: env_id, user_id: user_id} do
      {:ok, %{inserted_env: environment}} =
        LenraApplicationServices.create(user_id, %{
          name: "test-update",
          color: "FFFFFF",
          icon: "60189"
        })

      assert {:ok, %{inserted_datastore: _inserted_datastore}} = DatastoreServices.create(env_id, %{"name" => "users"})

      assert {:ok, %{inserted_datastore: _inserted_datastore}} =
               DatastoreServices.create(environment.id, %{"name" => "users"})
    end

    test "should create datastore if different name but same env_id", %{env_id: env_id, user_id: user_id} do
      {:ok, %{inserted_env: environment}} =
        LenraApplicationServices.create(user_id, %{
          name: "test-update",
          color: "FFFFFF",
          icon: "60189"
        })

      assert {:ok, %{inserted_datastore: _inserted_datastore}} = DatastoreServices.create(env_id, %{"name" => "users"})

      assert {:ok, %{inserted_datastore: _inserted_datastore}} =
               DatastoreServices.create(environment.id, %{"name" => "test"})
    end

    test "should return error if json invalid", %{env_id: env_id, user_id: _user_id} do
      assert {:error, :inserted_datastore, %{errors: [name: {"can't be blank", [validation: :required]}]},
              _changes_so_far} =
               DatastoreServices.create(env_id, %{
                 "datastore" => "users"
               })
    end
  end

  describe "DatastoreServices.delete_1/1" do
    test "should delete datastore if params valid", %{env_id: env_id, user_id: _user_id} do
      {:ok, %{inserted_datastore: inserted_datastore}} = DatastoreServices.create(env_id, %{"name" => "users"})

      datastore = Repo.get(Datastore, inserted_datastore.id)

      DatastoreServices.delete(datastore.id)

      deleted_data = Repo.get(Datastore, inserted_datastore.id)

      assert datastore.id == inserted_datastore.id
      assert deleted_data == nil
    end

    test "should return error id invalid", %{env_id: _env_id} do
      assert {:error, :datastore, :datastore_not_found, _changes_so_far} = DatastoreServices.delete(-1)
    end

    test "should also delete data", %{env_id: env_id, user_id: _user_id} do
      {:ok, %{inserted_datastore: inserted_datastore}} = DatastoreServices.create(env_id, %{"name" => "users"})

      datastore = Repo.get(Datastore, inserted_datastore.id)

      Repo.insert(Data.new(datastore.id, %{"name" => "test"}))
      Repo.insert(Data.new(datastore.id, %{"name" => "test2"}))
      Repo.insert(Data.new(datastore.id, %{"name" => "test3"}))

      datas =
        Repo.all(
          from(
            d in Data,
            where: d.datastore_id == ^datastore.id,
            select: d
          )
        )

      assert length(datas) == 3

      DatastoreServices.delete(datastore.id)

      deleted_datastore = Repo.get(Datastore, inserted_datastore.id)

      deleted_datas =
        Repo.all(
          from(
            d in Data,
            where: d.datastore_id == ^datastore.id,
            select: d
          )
        )

      assert deleted_datastore == nil
      assert Enum.empty?(deleted_datas)
    end
  end

  describe "DatastoreServices.update_1/1" do
    test "should update datastore if params valid", %{env_id: env_id, user_id: _user_id} do
      {:ok, %{inserted_datastore: inserted_datastore}} = DatastoreServices.create(env_id, %{"name" => "users"})

      datastore = Repo.get(Datastore, inserted_datastore.id)

      DatastoreServices.update(datastore.id, %{"name" => "test"})

      updated_data = Repo.get(Datastore, inserted_datastore.id)

      assert updated_data.name == "test"
    end

    test "should return error id invalid", %{env_id: _env_id} do
      assert {:error, :datastore, :datastore_not_found, _changes_so_far} =
               DatastoreServices.update(-1, %{"name" => "test"})
    end
  end
end
