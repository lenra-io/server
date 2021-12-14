defmodule Lenra.LenraDataTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Data, Datastore}

  setup do
    {:ok, data: create_application()}
  end

  defp create_application do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    {:ok, %{inserted_application: app}} = ApplicationTestHelper.register_minesweeper(user.id)

    {:ok, inserted_datastore} = Repo.insert(Datastore.new(app.id, "users"))

    %{datastore: inserted_datastore}
  end

  describe "lenra_data" do
    test "new/2 create data", %{
      data: %{datastore: datastore}
    } do
      {:ok, data} = Repo.insert(Data.new(datastore.id, %{name: "Test"}))

      assert data.data == %{name: "Test"}
      assert data.datastore_id == datastore.id
    end

    test "new/2 with invalid data should failed", %{
      data: %{datastore: datastore}
    } do
      data = Repo.insert(Data.new(datastore.id, nil))
      assert {:error, %{errors: [data: _error_message]}} = data
    end
  end
end
