# defmodule Lenra.LenraDataTest do
#  use Lenra.RepoCase, async: true
#
#  alias Lenra.{Dataspace}
#
#  setup do
#    {:ok, data: create_application()}
#  end
#
#  defp create_application do
#    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
#
#    {:ok, %{inserted_application: app}} = ApplicationTestHelper.register_minesweeper(user.id)
#
#    %{app: app}
#  end
#
#  describe "lenra_data" do
#    test "new/2 create data", %{
#      data: %{app: app}
#    } do
#      {:ok, dataspace} = Repo.insert(Dataspace.new(app.id, "test"))
#
#      assert dataspace.name == "test"
#      assert dataspace.application_id == app.id
#    end
#
#    test "new/2 with invalid data should failed", %{
#      data: %{app: app}
#    } do
#      dataspace_data = Repo.insert(Dataspace.new(app.id, nil))
#      assert {:error, %{errors: [name: _error_message]}} = dataspace_data
#    end
#  end
# end
#
