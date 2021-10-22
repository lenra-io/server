defmodule LenraServers.DatastoreServicesTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Repo, Datastore, DatastoreServices, LenraApplicationServices, LenraApplication}

  @moduledoc """
    Test the datastore services
  """

  setup do
    {:ok, app: create_and_return_application()}
  end

  defp create_and_return_application do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    LenraApplicationServices.create(user.id, %{
      name: "mine-sweeper",
      service_name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    })

    Enum.at(Repo.all(LenraApplication), 0)
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
    test "data", %{app: app} do
      {:ok, %Datastore{id: last_inserted_id}} =
        DatastoreServices.insert_data(app.creator_id, app.id, %{"test" => "test data"})

      %Datastore{
        data: %{"test" => "test data"}
      } = Repo.get(Datastore, last_inserted_id)

      DatastoreServices.update_data(last_inserted_id, %{data: %{"test" => "test data"}})

      datastore = Repo.get(Datastore, last_inserted_id)

      assert datastore.data == %{"test" => "test data"}
    end

    test "and check updated data", %{app: app} do
      {:ok, %Datastore{id: last_inserted_id}} =
        DatastoreServices.insert_data(app.creator_id, app.id, %{"test" => "test data"})

      DatastoreServices.update_data(last_inserted_id, %{data: %{"test" => "test new data"}})

      datastore = Repo.get(Datastore, last_inserted_id)

      assert app.creator_id == datastore.owner_id
      assert app.id == datastore.application_id

      assert datastore.data == %{"test" => "test new data"}
    end
  end
end
