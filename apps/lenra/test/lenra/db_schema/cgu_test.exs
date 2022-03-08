defmodule Lenra.CguTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Cgu}

  @valid_cgu %{link: "Test", version: "1.0.0", hash: "test"}
  @cgu_same_hash %{link: "test", version: "1.2.0", hash: "test"}
  @cgu_same_version %{link: "test", version: "1.0.0", hash: "Test"}
  @cgu_same_link %{link: "Test", version: "1.2.0", hash: "Test"}
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

    test "hash must be unique" do
      Cgu.new(@valid_cgu) |> Repo.insert()

      assert_raise Ecto.ConstraintError,
                   "constraint error when attempting to insert struct:\n\n    * cgu_hash_index (unique_constraint)\n\nIf you would like to stop this constraint violation from raising an\nexception and instead add it as an error to your changeset, please\ncall `unique_constraint/3` on your changeset with the constraint\n`:name` as an option.\n\nThe changeset defined the following constraints:\n\n    * cgu_link_version_hash_index (unique_constraint)\n",
                   fn -> @cgu_same_hash |> Cgu.new() |> Repo.insert() end
    end

    test "link must be unique" do
      Cgu.new(@valid_cgu) |> Repo.insert()

      assert_raise Ecto.ConstraintError,
                   "constraint error when attempting to insert struct:\n\n    * cgu_link_index (unique_constraint)\n\nIf you would like to stop this constraint violation from raising an\nexception and instead add it as an error to your changeset, please\ncall `unique_constraint/3` on your changeset with the constraint\n`:name` as an option.\n\nThe changeset defined the following constraints:\n\n    * cgu_link_version_hash_index (unique_constraint)\n",
                   fn -> @cgu_same_link |> Cgu.new() |> Repo.insert() end
    end

    test "version must be unique" do
      Cgu.new(@valid_cgu) |> Repo.insert()

      assert_raise Ecto.ConstraintError,
                   "constraint error when attempting to insert struct:\n\n    * cgu_version_index (unique_constraint)\n\nIf you would like to stop this constraint violation from raising an\nexception and instead add it as an error to your changeset, please\ncall `unique_constraint/3` on your changeset with the constraint\n`:name` as an option.\n\nThe changeset defined the following constraints:\n\n    * cgu_link_version_hash_index (unique_constraint)\n",
                   fn -> @cgu_same_version |> Cgu.new() |> Repo.insert() end
    end
  end
end
