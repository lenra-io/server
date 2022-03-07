defmodule Lenra.LenraCguTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Cgu, UserAcceptCguVersion}

  @valide_cgu %{link: "Test", version: "1.0.0", hash: "test"}
  @invalide_cgu %{link: nil, version: nil, hash: nil}

  describe "lenra_cgu" do
    test "new/1 with valid data creates a cgu" do
      assert %{changes: cgu, valid?: true} = Cgu.new(@valide_cgu)
      assert cgu.link == @valide_cgu.link
      assert cgu.version == @valide_cgu.version
      assert cgu.hash == @valide_cgu.hash
    end

    test "new/2 with invalid data creates a cgu" do
      assert %{changes: _cgu, valid?: false} = Cgu.new(@invalide_cgu)
    end

    test "attached to cgu should succed" do
      # Test create and insert cgu
      cgu = Cgu.new(@valide_cgu)
      {:ok, %Cgu{} = inserted_cgu} = Repo.insert(cgu)

      assert %{valid?: true} = cgu

      [head | _tail] = Repo.all(from(Cgu))
      assert head == inserted_cgu
    end
  end

  describe "lenra_user_accept_cgu_version" do
    test "new/1 with valid and invalid data creates a user_accept_cgu_version" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      cgu = Cgu.new(@valide_cgu)
      {:ok, %Cgu{} = inserted_cgu} = Repo.insert(cgu)

      assert %{changes: user_accept_cgu_version, valid?: true} =
               UserAcceptCguVersion.new(%{user_id: user.id, cgu_id: inserted_cgu.id})

      assert %{changes: _user_accept_cgu_version1, valid?: false} =
               UserAcceptCguVersion.new(%{user_id: nil, cgu_id: nil})

      assert user_accept_cgu_version.user_id == user.id
      assert user_accept_cgu_version.cgu_id == inserted_cgu.id
    end
  end
end
