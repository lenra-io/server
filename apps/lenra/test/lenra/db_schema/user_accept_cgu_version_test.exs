defmodule Lenra.UserAcceptCguVersionTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Cgu, UserAcceptCguVersion}

  @valid_cgu %{link: "Test", version: "1.0.0", hash: "test"}

  describe "lenra_user_accept_cgu_version" do
    test "new/1 with valid data creates a user_accept_cgu_version" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      cgu = Cgu.new(@valid_cgu)
      {:ok, %Cgu{} = inserted_cgu} = Repo.insert(cgu)

      assert %{changes: user_accept_cgu_version, valid?: true} =
               UserAcceptCguVersion.new(%{user_id: user.id, cgu_id: inserted_cgu.id})

      assert user_accept_cgu_version.user_id == user.id
      assert user_accept_cgu_version.cgu_id == inserted_cgu.id
    end

    test "new/1 with invalid data creates an invalid user_accept_cgu_version" do
      assert %{changes: _user_accept_cgu_version1, valid?: false} =
               UserAcceptCguVersion.new(%{user_id: nil, cgu_id: nil})
    end
  end
end