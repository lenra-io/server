defmodule LenraServers.DatastoreServicesTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Repo, DatastoreServices, LenraApplicationServices, LenraApplication, Dataspace}
  alias ApplicationRunner.{Datastore}

  @moduledoc """
    Test the datastore services
  """

  setup do
    {:ok, data: create_and_return_dataspace()}
  end

  defp create_and_return_dataspace do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    {:ok, %{inserted_application: app}} =
      LenraApplicationServices.create(user.id, %{
        name: "mine-sweeper",
        service_name: "mine-sweeper",
        color: "FFFFFF",
        icon: "60189"
      })

    {:ok, dataspace} = Repo.insert(Dataspace.new(app.id, "test"))

    %{dataspace: dataspace, user: user}
  end

  describe "get" do
    test "data from datastore but datastore does not exist", %{app: app} do
      assert nil ==
               DatastoreServices.get_old_data(
                 app.creator_id,
                 app.id
               )
    end

    test "data from existing datastore", %{app: app} do
      DatastoreServices.upsert_data(app.creator_id, app.id, %{"foo" => "bar"})

      assert %Datastore{data: %{"foo" => "bar"}} =
               DatastoreServices.get_old_data(
                 app.creator_id,
                 app.id
               )
    end

    test "datastore", %{app: app} do
      DatastoreServices.upsert_data(app.creator_id, app.id, %{"foo" => "bar"})

      datastore = Repo.get(Datastore, last_inserted_id)

      assert datastore.owner_id == app.creator_id
      assert datastore.application_id == app.id
      assert datastore.data == %{"foo" => "bar"}
    end
  end

  describe "insert" do
    test "data", %{data: %{dataspace: dataspace, user: user}} do
      {:ok, %Datastore{id: last_inserted_id}} =
        DatastoreServices.insert_data(user.id, dataspace.id, %{"test" => "test data"})

      %Datastore{
        data: %{"test" => "test data"}
      } = Repo.get(Datastore, last_inserted_id)

      DatastoreServices.update_data(last_inserted_id, %{data: %{"test" => "test data"}})

      datastore = Repo.get(Datastore, last_inserted_id)

      assert datastore.data == %{"test" => "test data"}
    end

    test "and check updated data", %{data: %{dataspace: dataspace, user: user}} do
      {:ok, %Datastore{id: last_inserted_id}} =
        DatastoreServices.insert_data(user.id, dataspace.id, %{"test" => "test data"})

      DatastoreServices.update_data(last_inserted_id, %{data: %{"test" => "test new data"}})

      datastore = Repo.get(Datastore, last_inserted_id)

      assert user.id == datastore.owner_id
      assert dataspace.id == datastore.dataspace_id

      assert datastore.data == %{"test" => "test new data"}
    end
  end
end
