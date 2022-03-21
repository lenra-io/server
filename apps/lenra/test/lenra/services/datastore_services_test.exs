defmodule Lenra.DatastoreServicesTest do
  @moduledoc """
    Test the datastore services
  """
  # TODO: This test is no longer match the data schema and will be rework in another PR

  # use Lenra.RepoCase, async: true

  # alias Lenra.{
  #   Datastore,
  #   DatastoreServices,
  #   LenraApplication,
  #   LenraApplicationServices,
  #   Repo
  # }

  # setup do
  #   {:ok, app: create_and_return_application()}
  # end

  # defp create_and_return_application do
  #   {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

  #   LenraApplicationServices.create(user.id, %{
  #     name: "mine-sweeper",
  #     color: "FFFFFF",
  #     icon: "60189"
  #   })

  #   Enum.at(Repo.all(LenraApplication), 0)
  # end

  # describe "get" do
  #   test "data from datastore but datastore does not exist", %{app: app} do
  #     assert nil ==
  #              DatastoreServices.get_old_data(
  #                app.creator_id,
  #                app.id
  #              )
  #   end

  #   test "data from existing datastore", %{app: app} do
  #     DatastoreServices.upsert_data(app.creator_id, app.id, %{"foo" => "bar"})

  #     assert %Datastore{data: %{"foo" => "bar"}} =
  #              DatastoreServices.get_old_data(
  #                app.creator_id,
  #                app.id
  #              )
  #   end

  #   test "datastore", %{app: app} do
  #     DatastoreServices.upsert_data(app.creator_id, app.id, %{"foo" => "bar"})

  #     assert (%Datastore{} = datastore) = DatastoreServices.get_by(user_id: app.creator_id, application_id: app.id)

  #     assert datastore.user_id == app.creator_id
  #     assert datastore.application_id == app.id
  #     assert datastore.data == %{"foo" => "bar"}
  #   end

  #   test "datastore but does not exist", %{app: app} do
  #     assert nil == DatastoreServices.get_by(user_id: app.creator_id, application_id: app.id)
  #   end
  # end

  # describe "insert" do
  #   test "data", %{app: app} do
  #     assert {:ok,
  #             %Datastore{
  #               data: %{"data" => "test data"}
  #             }} = DatastoreServices.upsert_data(app.creator_id, app.id, %{"data" => "test data"})

  #     assert (%Datastore{} = datastore) = Repo.get_by(Datastore, user_id: app.creator_id, application_id: app.id)

  #     assert datastore.data == %{"data" => "test data"}
  #   end

  #   test "and check updated data", %{app: app} do
  #     DatastoreServices.upsert_data(app.creator_id, app.id, %{"data" => "test data"})

  #     assert {:ok, %Datastore{data: %{"data" => "test new data"}}} =
  #              DatastoreServices.upsert_data(app.creator_id, app.id, %{"data" => "test new data"})

  #     assert (%Datastore{} = datastore) = Repo.get_by(Datastore, user_id: app.creator_id, application_id: app.id)

  #     assert datastore.data == %{"data" => "test new data"}
  #   end
  # end
end
