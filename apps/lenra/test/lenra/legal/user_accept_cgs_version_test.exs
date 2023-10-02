defmodule Lenra.Legal.UserAcceptCGSVersionTest do
  use Lenra.RepoCase, async: true

  alias Lenra.Legal.{CGS, UserAcceptCGSVersion}

  @valid_cgs1 %{path: "Test", version: 2, hash: "test"}
  @valid_cgs2 %{path: "/tmp/aeg", version: 3, hash: "Test"}
  @user %{
    "first_name" => "Test",
    "last_name" => "test",
    "email" => "test.test@lenra.fr",
    "password" => "Testtest@thefirst",
    "password_confirmation" => "Testtest@thefirst"
  }

  describe "lenra_user_accept_cgs_version" do
    test "with valid data creates a user_accept_cgs_version" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      cgs = CGS.new(@valid_cgs1)
      {:ok, %CGS{} = inserted_cgs} = Repo.insert(cgs)

      assert %{changes: user_accept_cgs_version, valid?: true} =
               UserAcceptCGSVersion.new(%{user_id: user.id, cgs_id: inserted_cgs.id})

      assert user_accept_cgs_version.user_id == user.id
      assert user_accept_cgs_version.cgs_id == inserted_cgs.id
    end

    test "new/1 with invalid data creates an invalid user_accept_cgs_version" do
      assert %{changes: _user_accept_cgs_version1, valid?: false} =
               UserAcceptCGSVersion.new(%{user_id: nil, cgs_id: nil})
    end

    test "trigger should not fail if latest cgs is accepted" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

      {:ok, %CGS{} = _inserted_cgs} = @valid_cgs1 |> CGS.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      cgs1 =
        @valid_cgs2
        |> CGS.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)

      {:ok, %CGS{} = inserted_cgs1} = Repo.insert(cgs1)

      assert {:ok, %UserAcceptCGSVersion{}} =
               Repo.insert(UserAcceptCGSVersion.new(%{user_id: user.id, cgs_id: inserted_cgs1.id}))
    end

    test "trigger should fail if accepted cgs is not the latest" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

      {:ok, %CGS{} = inserted_cgs} = @valid_cgs1 |> CGS.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      cgs1 =
        @valid_cgs2
        |> CGS.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)

      {:ok, %CGS{} = _inserted_cgs1} = Repo.insert(cgs1)

      assert_raise Postgrex.Error,
                   "ERROR P0001 (raise_exception) Not latest CGS",
                   fn -> Repo.insert(UserAcceptCGSVersion.new(%{user_id: user.id, cgs_id: inserted_cgs.id})) end
    end

    test "new/1 can't add 2 same cgs_id and user_id in the database" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, %CGS{} = inserted_cgs} = @valid_cgs1 |> CGS.new() |> Repo.insert()

      assert {:ok, %UserAcceptCGSVersion{}} =
               %{user_id: user.id, cgs_id: inserted_cgs.id} |> UserAcceptCGSVersion.new() |> Repo.insert()

      assert {:error, %{errors: [user_id: {"has already been taken", _}]}} =
               %{user_id: user.id, cgs_id: inserted_cgs.id} |> UserAcceptCGSVersion.new() |> Repo.insert()
    end

    test "new/1 can add 2 same cgs_id for 2 different user_id in the database" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, %CGS{} = inserted_cgs} = @valid_cgs1 |> CGS.new() |> Repo.insert()

      assert {:ok, %UserAcceptCGSVersion{}} =
               %{user_id: user.id, cgs_id: inserted_cgs.id} |> UserAcceptCGSVersion.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      cgs1 =
        @valid_cgs2
        |> CGS.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)

      {:ok, %CGS{} = inserted_cgs1} = cgs1 |> Repo.insert()

      assert {:ok, %UserAcceptCGSVersion{}} =
               %{user_id: user.id, cgs_id: inserted_cgs1.id} |> UserAcceptCGSVersion.new() |> Repo.insert()
    end

    test "new/1 can add 2 same user_id for 2 different cgs_id in the database" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, %{inserted_user: user1}} = UserTestHelper.register_user(@user)
      {:ok, %CGS{} = inserted_cgs} = @valid_cgs1 |> CGS.new() |> Repo.insert()

      assert {:ok, %UserAcceptCGSVersion{}} =
               %{user_id: user.id, cgs_id: inserted_cgs.id} |> UserAcceptCGSVersion.new() |> Repo.insert()

      assert {:ok, %UserAcceptCGSVersion{}} =
               %{user_id: user1.id, cgs_id: inserted_cgs.id} |> UserAcceptCGSVersion.new() |> Repo.insert()
    end
  end
end
