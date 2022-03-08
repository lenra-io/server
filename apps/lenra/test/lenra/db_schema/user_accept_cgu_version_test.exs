defmodule Lenra.UserAcceptCguVersionTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Cgu, UserAcceptCguVersion}

  @valid_cgu1 %{link: "Test", version: "1.0.0", hash: "test"}
  @valid_cgu2 %{link: "/tmp/aeg", version: "2.0.0", hash: "Test"}

  describe "lenra_user_accept_cgu_version" do
    test "with valid data creates a user_accept_cgu_version" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      cgu = Cgu.new(@valid_cgu1)
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

    test "trigger should not fail if latest cgu is accepted" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

      {:ok, %Cgu{} = _inserted_cgu} = @valid_cgu1 |> Cgu.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      cgu1 =
        @valid_cgu2
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)

      {:ok, %Cgu{} = inserted_cgu1} = Repo.insert(cgu1)

      assert {:ok, %UserAcceptCguVersion{}} =
               Repo.insert(UserAcceptCguVersion.new(%{user_id: user.id, cgu_id: inserted_cgu1.id}))
    end

    test "trigger should fail if accepted cgu is not the latest" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

      {:ok, %Cgu{} = inserted_cgu} = @valid_cgu1 |> Cgu.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      cgu1 =
        @valid_cgu2
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)

      {:ok, %Cgu{} = _inserted_cgu1} = Repo.insert(cgu1)

      assert_raise Postgrex.Error,
                   "ERROR P0001 (raise_exception) Not latest CGU",
                   fn -> Repo.insert(UserAcceptCguVersion.new(%{user_id: user.id, cgu_id: inserted_cgu.id})) end
    end

    test "new/1 can't add 2 same cgu_id and user_id in the database" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, %Cgu{} = inserted_cgu} = @valid_cgu1 |> Cgu.new() |> Repo.insert()

      assert %{changes: user_accept_cgu_version, valid?: true} =
               UserAcceptCguVersion.new(%{user_id: user.id, cgu_id: inserted_cgu.id})

      assert %{changes: _user_accept_cgu_version, valid?: false} =
               UserAcceptCguVersion.new(%{user_id: user.id, cgu_id: inserted_cgu.id})
    end

    test "new/1 can add 2 same cgu_id for 2 different user_id in the database" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, %Cgu{} = inserted_cgu} = @valid_cgu1 |> Cgu.new() |> Repo.insert()
      {:ok, %Cgu{} = inserted_cgu1} = @valid_cgu2 |> Cgu.new() |> Repo.insert()

      assert %{changes: _user_accept_cgu_version, valid?: true} =
               UserAcceptCguVersion.new(%{user_id: user.id, cgu_id: inserted_cgu.id})

      assert %{changes: _user_accept_cgu_version, valid?: true} =
               UserAcceptCguVersion.new(%{user_id: user.id, cgu_id: inserted_cgu1.id})
    end

    test "new/1 can add 2 same user_id for 2 different cgu_id in the database" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, %Cgu{} = inserted_cgu} = @valid_cgu1 |> Cgu.new() |> Repo.insert()
      {:ok, %Cgu{} = inserted_cgu1} = @valid_cgu2 |> Cgu.new() |> Repo.insert()

      assert %{changes: _user_accept_cgu_version, valid?: true} =
               UserAcceptCguVersion.new(%{user_id: user.id, cgu_id: inserted_cgu.id})

      assert %{changes: _user_accept_cgu_version, valid?: true} =
               UserAcceptCguVersion.new(%{user_id: user.id, cgu_id: inserted_cgu1.id})
    end
  end
end
