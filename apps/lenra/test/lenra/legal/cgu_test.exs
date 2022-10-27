defmodule Lenra.CGUTest do
  use Lenra.RepoCase, async: true
  use ExUnit.Case

  alias Lenra.Legal.CGU

  @valid_cgu %{path: "Test", version: 2, hash: "test"}
  @cgu_same_hash %{path: "test", version: 3, hash: "test"}
  @cgu_same_version %{path: "test", version: 2, hash: "Test"}
  @cgu_same_path %{path: "Test", version: 3, hash: "Test"}
  @invalid_cgu %{path: nil, version: nil, hash: nil}

  describe "lenra_cgu" do
    test "new/1 with valid data creates a cgu" do
      assert %{changes: cgu, valid?: true} = CGU.new(@valid_cgu)
      assert cgu.path == @valid_cgu.path
      assert cgu.version == @valid_cgu.version
      assert cgu.hash == @valid_cgu.hash
    end

    test "new/1 with invalid data creates an invalid cgu" do
      assert %{changes: _cgu, valid?: false} = CGU.new(@invalid_cgu)
    end

    test "inserting a valid cgu should succeed" do
      # Test create and insert cgu
      cgu = CGU.new(@valid_cgu)
      {:ok, %CGU{} = inserted_cgu} = Repo.insert(cgu)

      assert %{valid?: true} = cgu

      all_cgu = Repo.all(from(CGU))
      assert Enum.member?(all_cgu, inserted_cgu)
    end

    test "inserting an invalid cgu should not succeed" do
      # Test create and insert cgu
      cgu = CGU.new(@invalid_cgu)

      assert {:error,
              %{errors: [path: {"can't be blank", _}, version: {"can't be blank", _}, hash: {"can't be blank", _}]}} =
               Repo.insert(cgu)
    end

    test "hash must be unique" do
      @valid_cgu |> CGU.new() |> Repo.insert()

      assert {:error, %Ecto.Changeset{errors: [hash: {"has already been taken", _}]}} =
               @cgu_same_hash |> CGU.new() |> Repo.insert()
    end

    test "path must be unique" do
      @valid_cgu |> CGU.new() |> Repo.insert()

      assert {:error, %Ecto.Changeset{errors: [path: {"has already been taken", _}]}} =
               @cgu_same_path |> CGU.new() |> Repo.insert()
    end

    test "version must be unique" do
      @valid_cgu |> CGU.new() |> Repo.insert()

      assert {:error, %Ecto.Changeset{errors: [version: {"has already been taken", _}]}} =
               @cgu_same_version |> CGU.new() |> Repo.insert()
    end
  end
end