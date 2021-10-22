defmodule Lenra.LenraDatastoreUsersTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Datastore}

  setup do
    {:ok, data: create_application()}
  end

  defp create_application do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    {:ok, %{inserted_application: app}} = ApplicationTestHelper.register_minesweeper(user.id)

    %{application: app, user_uuid: user.id}
  end

  describe "lenra_datastore_users" do
    test "new/2 create datastore for user", %{
      data: %{application: application, user_uuid: owner_id}
    } do
      {:ok, inserted_app_data} = Repo.insert(Datastore.new(owner_id, application.id, %{data: %{test: "test"}}))

      {:ok, app_data} = Repo.fetch_by(Datastore, %{id: inserted_app_data.id})

      with %{id: application_id} <- application,
           %{application_id: app_data_id, data: app_data_json} <- app_data do
        assert application_id == app_data_id
        assert %{"test" => "test"} == app_data_json
      else
        _ -> assert false
      end
    end

    test "new/2 with invalid data should failed", %{
      data: %{application: application, user_uuid: owner_id}
    } do
      app_data = Repo.insert(Datastore.new(owner_id, application.id, %{json_data: %{test: "test"}}))
      assert {:error, %{errors: [data: _error_message]}} = app_data
    end
  end
end
