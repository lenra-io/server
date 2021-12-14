defmodule Lenra.LenraDatastoreTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Datastore}

  setup do
    {:ok, data: create_application()}
  end

  defp create_application do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    {:ok, %{inserted_application: app}} = ApplicationTestHelper.register_minesweeper(user.id)

    %{app: app}
  end

  describe "lenra_datastore" do
    test "new/2 create datastore", %{
      data: %{app: app}
    } do
      {:ok, inserted_datastore} = Repo.insert(Datastore.new(app.id, "users"))

      datastore = Repo.get_by(Datastore, %{id: inserted_datastore.id})

      with %{id: app_id} <- app,
           %{application_id: datastore_app_id, name: datastore_name} <- datastore do
        assert app_id == datastore_app_id
        assert "users" == datastore_name
      else
        _ -> assert false
      end
    end

    test "new/2 with invalid data should failed", %{
      data: %{app: _app}
    } do
      datastore = Repo.insert(Datastore.new(-1, "test"))
      assert {:error, %{errors: [application_id: _error_message]}} = datastore
    end
  end
end
