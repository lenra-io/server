defmodule Lenra.UserAcceptCguVersionTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Cgu, UserAcceptCguVersion}

  @user %{
    "first_name" => "Test",
    "last_name" => "test",
    "email" => "test.test@lenra.fr",
    "password" => "Testtest@thefirst",
    "password_confirmation" => "Testtest@thefirst"
  }

  @valid_cgu %{link: "Test", version: "1.0.0", hash: "test"}
  @valid_cgu1 %{link: "test", version: "2.0.0", hash: "Test"}
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

    test "new/1 can't add 2 same cgu_id and user_id in the database" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, %Cgu{} = inserted_cgu} = @valid_cgu |> Cgu.new() |> Repo.insert()

      assert {:ok, %UserAcceptCguVersion{}} =
               %{user_id: user.id, cgu_id: inserted_cgu.id} |> UserAcceptCguVersion.new() |> Repo.insert()

      assert {:error, %Ecto.Changeset{}} =
               %{user_id: user.id, cgu_id: inserted_cgu.id} |> UserAcceptCguVersion.new() |> Repo.insert()
    end

    test "new/1 can add 2 same cgu_id for 2 different user_id in the database" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, %Cgu{} = inserted_cgu} = @valid_cgu |> Cgu.new() |> Repo.insert()

      assert {:ok, %UserAcceptCguVersion{}} =
               %{user_id: user.id, cgu_id: inserted_cgu.id} |> UserAcceptCguVersion.new() |> Repo.insert()

      {:ok, %Cgu{} = inserted_cgu1} = @valid_cgu1 |> Cgu.new() |> Repo.insert()

      assert {:ok, %UserAcceptCguVersion{}} =
               %{user_id: user.id, cgu_id: inserted_cgu1.id} |> UserAcceptCguVersion.new() |> Repo.insert()
    end

    test "new/1 can add 2 same user_id for 2 different cgu_id in the database" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

      {:ok, %{inserted_user: user1}} = UserTestHelper.register_user(@user)
      {:ok, %Cgu{} = inserted_cgu} = @valid_cgu |> Cgu.new() |> Repo.insert()

      assert {:ok, %UserAcceptCguVersion{}} =
               %{user_id: user.id, cgu_id: inserted_cgu.id} |> UserAcceptCguVersion.new() |> Repo.insert()

      assert {:ok, %UserAcceptCguVersion{}} =
               %{user_id: user1.id, cgu_id: inserted_cgu.id} |> UserAcceptCguVersion.new() |> Repo.insert()
    end
  end
end
