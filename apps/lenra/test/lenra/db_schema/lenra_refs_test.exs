defmodule Lenra.LenraRefsTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Data, Datastore, Refs}

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
    test "new/2 create refs", %{
      data: %{datastore: datastore}
    } do
      {:ok, data_referencer} = Repo.insert(Data.new(datastore.id, %{name: "Test"}))
      {:ok, data_referenced} = Repo.insert(Data.new(datastore.id, %{todo: "this_is_my_todo"}))

      {:ok, inserted_refs} = Repo.insert(Refs.new(data_referencer.id, data_referenced.id))

      refs =
        Repo.get_by(Refs, %{id: inserted_refs.id})
        |> Repo.preload([:referencer, :referenced])

      assert refs.referencer.data == %{"name" => "Test"}
      assert refs.referenced.data == %{"todo" => "this_is_my_todo"}
    end

    test "new/2 with invalid refs should failed", %{
      data: %{datastore: datastore}
    } do
      data = Repo.insert(Data.new(datastore.id, nil))
      assert {:error, %{errors: [data: _error_message]}} = data
    end
  end
end
