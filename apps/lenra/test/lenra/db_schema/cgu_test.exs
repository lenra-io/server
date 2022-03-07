defmodule Lenra.CguTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Cgu, UserAcceptCguVersion}

  @valid_cgu %{link: "Test", version: "1.0.0", hash: "test"}
  @invalid_cgu %{link: nil, version: nil, hash: nil}

  describe "lenra_cgu" do
    test "new/1 with valid data creates a cgu" do
      assert %{changes: cgu, valid?: true} = Cgu.new(@valid_cgu)
      assert cgu.link == @valid_cgu.link
      assert cgu.version == @valid_cgu.version
      assert cgu.hash == @valid_cgu.hash
    end

    test "new/1 with invalid data creates an invalid cgu" do
      assert %{changes: _cgu, valid?: false} = Cgu.new(@invalid_cgu)
    end

    test "inserting a valid cgu should succeed" do
      # Test create and insert cgu
      cgu = Cgu.new(@valid_cgu)
      {:ok, %Cgu{} = inserted_cgu} = Repo.insert(cgu)

      assert %{valid?: true} = cgu

      [head | _tail] = Repo.all(from(Cgu))
      assert head == inserted_cgu
    end

    test "inserting an invalid cgu should not succeed" do
      # Test create and insert cgu
      cgu = Cgu.new(@invalid_cgu)

      assert {:error,
              %{errors: [link: {"can't be blank", _}, version: {"can't be blank", _}, hash: {"can't be blank", _}]}} =
               Repo.insert(cgu)
    end
  end
end
