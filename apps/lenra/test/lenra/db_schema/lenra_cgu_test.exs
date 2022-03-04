defmodule Lenra.LenraCguTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Cgu}

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
end
