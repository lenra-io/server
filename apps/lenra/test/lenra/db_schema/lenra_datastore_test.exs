defmodule Lenra.LenraDatastoreTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Datastore, Dataspace}

  # setup do
  #  {:ok, data: create_dataspace()}
  # end

  # defp create_dataspace do
  #  {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
  #
  #  {:ok, %{inserted_application: app}} = ApplicationTestHelper.register_minesweeper(user.id)
  #
  #  {:ok, dataspace} = Repo.insert(Dataspace.new(app.id, "test"))
  #
  #  %{dataspace: dataspace, user_uuid: user.id}
  # end

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
      temp = Datastore.new(app.id, "users")
      IO.puts(inspect(temp))
      {:ok, inserted_datastore} = Repo.insert(temp)

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
      data: %{app: app}
    } do
      datastore = Repo.insert(Datastore.new(-1, "test"))
      assert {:error, %{errors: [application_id: _error_message]}} = datastore
    end
  end
end
