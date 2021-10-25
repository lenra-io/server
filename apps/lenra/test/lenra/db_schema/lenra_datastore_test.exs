defmodule Lenra.LenraDatastoreTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Datastore, Dataspace}

  setup do
    {:ok, data: create_dataspace()}
  end

  defp create_dataspace do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    {:ok, %{inserted_application: app}} = ApplicationTestHelper.register_minesweeper(user.id)

    {:ok, dataspace} = Repo.insert(Dataspace.new(app.id, "test"))

    %{dataspace: dataspace, user_uuid: user.id}
  end

  describe "lenra_datastore" do
    test "new/2 create datastore for user", %{
      data: %{dataspace: dataspace, user_uuid: owner_id}
    } do
      {:ok, inserted_datastore} = Repo.insert(Datastore.new(owner_id, dataspace.id, %{test: "test"}))

      datastore = Repo.get_by(Datastore, %{id: inserted_datastore.id})

      with %{id: dataspace_id} <- dataspace,
           %{dataspace_id: datastore_dataspace_id, data: datastore_json} <- datastore do
        assert dataspace_id == datastore_dataspace_id
        assert %{"test" => "test"} == datastore_json
      else
        _ -> assert false
      end
    end

    test "new/2 with invalid data should failed", %{
      data: %{user_uuid: owner_id}
    } do
      app_data = Repo.insert(Datastore.new(owner_id, -1, %{"test" => "test"}))
      assert {:error, %{errors: [dataspace_id: _error_message]}} = app_data
    end
  end
end
