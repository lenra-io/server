defmodule Lenra.CGSTest do
  use Lenra.RepoCase, async: true
  use ExUnit.Case

  alias Lenra.Legal.CGS

  @next_cgs_version 100_000

  @valid_cgs %{path: "Test", version: @next_cgs_version, hash: "test"}
  @cgs_same_hash %{path: "test", version: @next_cgs_version + 1, hash: "test"}
  @cgs_same_version %{path: "test", version: @next_cgs_version, hash: "Test"}
  @cgs_same_path %{path: "Test", version: @next_cgs_version + 1, hash: "Test"}
  @invalid_cgs %{path: nil, version: nil, hash: nil}

  describe "lenra_cgs" do
    test "new/1 with valid data creates a cgs" do
      assert %{changes: cgs, valid?: true} = CGS.new(@valid_cgs)
      assert cgs.path == @valid_cgs.path
      assert cgs.version == @valid_cgs.version
      assert cgs.hash == @valid_cgs.hash
    end

    test "new/1 with invalid data creates an invalid cgs" do
      assert %{changes: _cgs, valid?: false} = CGS.new(@invalid_cgs)
    end

    test "inserting a valid cgs should succeed" do
      # Test create and insert cgs
      cgs = CGS.new(@valid_cgs)
      {:ok, %CGS{} = inserted_cgs} = Repo.insert(cgs)

      assert %{valid?: true} = cgs

      all_cgs = Repo.all(from(CGS))
      assert Enum.member?(all_cgs, inserted_cgs)
    end

    test "inserting an invalid cgs should not succeed" do
      # Test create and insert cgs
      cgs = CGS.new(@invalid_cgs)

      assert {:error,
              %{errors: [path: {"can't be blank", _}, version: {"can't be blank", _}, hash: {"can't be blank", _}]}} =
               Repo.insert(cgs)
    end

    test "hash must be unique" do
      @valid_cgs |> CGS.new() |> Repo.insert()

      assert {:error, %Ecto.Changeset{errors: [hash: {"has already been taken", _}]}} =
               @cgs_same_hash |> CGS.new() |> Repo.insert()
    end

    test "path must be unique" do
      @valid_cgs |> CGS.new() |> Repo.insert()

      assert {:error, %Ecto.Changeset{errors: [path: {"has already been taken", _}]}} =
               @cgs_same_path |> CGS.new() |> Repo.insert()
    end

    test "version must be unique" do
      @valid_cgs |> CGS.new() |> Repo.insert()

      assert {:error, %Ecto.Changeset{errors: [version: {"has already been taken", _}]}} =
               @cgs_same_version |> CGS.new() |> Repo.insert()
    end
  end
end
