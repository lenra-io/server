defmodule Lenra.LegalTest do
  use Lenra.RepoCase, async: true

  alias Lenra.Errors.BusinessError
  alias Lenra.Legal
  alias Lenra.Legal.{CGU, UserAcceptCGUVersion}

  @valid_cgu1 %{path: "Test", version: 2, hash: "test"}
  @valid_cgu2 %{path: "Test1", version: 3, hash: "Test1"}
  @valid_cgu3 %{path: "Test2", version: 4, hash: "Test2"}
  @valid_cgu4 %{path: "Test3", version: 5, hash: "Test3"}

  describe "get_latest_cgu" do
    test "insert 2 cgu and check if the service take the latest" do
      {:ok, %CGU{} = _inserted_cgu} = @valid_cgu1 |> CGU.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, %CGU{} = inserted_cgu1} =
        @valid_cgu2
        |> CGU.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      assert {:ok, inserted_cgu1} == Legal.get_latest_cgu()
    end

    test "insert 4 cgu and check if the service take the latest" do
      {:ok, %CGU{} = _inserted_cgu} = @valid_cgu1 |> CGU.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, %CGU{} = _inserted_cgu1} =
        @valid_cgu2
        |> CGU.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      date2 = DateTime.utc_now() |> DateTime.add(8, :second) |> DateTime.truncate(:second)

      {:ok, %CGU{} = _inserted_cgu2} =
        @valid_cgu3
        |> CGU.new()
        |> Ecto.Changeset.put_change(:inserted_at, date2)
        |> Repo.insert()

      date3 = DateTime.utc_now() |> DateTime.add(12, :second) |> DateTime.truncate(:second)

      {:ok, %CGU{} = inserted_cgu3} =
        @valid_cgu4
        |> CGU.new()
        |> Ecto.Changeset.put_change(:inserted_at, date3)
        |> Repo.insert()

      assert {:ok, inserted_cgu3} == Legal.get_latest_cgu()
    end
  end

  describe "accept" do
    setup do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

      %{user: user}
    end

    test "existing cgu", %{user: user} do
      {:ok, cgu} = Repo.insert(CGU.new(%{path: "test.html", hash: "a", version: 2}))
      assert {:ok, %{accepted_cgu: _cgu}} = Legal.accept_cgu(cgu.id, user.id)
    end

    test "not latest cgu", %{user: user} do
      {:ok, cgu} = Repo.insert(CGU.new(%{path: "test.html", hash: "a", version: 2}))

      Repo.insert(
        %{path: "test2.html", hash: "b", version: 3}
        |> CGU.new()
        |> Ecto.Changeset.put_change(
          :inserted_at,
          DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)
        )
      )

      assert BusinessError.not_latest_cgu_tuple() == Legal.accept_cgu(cgu.id, user.id)
    end

    test "not existing user", %{user: _user} do
      {:ok, cgu} = Repo.insert(CGU.new(%{path: "test.html", hash: "a", version: 2}))

      assert {:error, :accepted_cgu, %{errors: [user_id: {"does not exist", _constraints}]}, _any} =
               Legal.accept_cgu(cgu.id, -1)
    end

    test "latest cgu", %{user: user} do
      Repo.insert(CGU.new(%{path: "test.html", hash: "a", version: 2}))

      {:ok, cgu} =
        Repo.insert(
          %{path: "test2.html", hash: "b", version: 3}
          |> CGU.new()
          |> Ecto.Changeset.put_change(
            :inserted_at,
            DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)
          )
        )

      assert {:ok, %{accepted_cgu: _cgu}} = Legal.accept_cgu(cgu.id, user.id)
    end
  end

  describe "user_accepted_latest_cgu?" do
    test "No CGU in database" do
      Repo.delete_all(from(CGU))
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

      assert true == Legal.user_accepted_latest_cgu?(user.id)
    end

    test "User did not accept CGU" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      %{path: "a", version: 2, hash: "a"} |> CGU.new() |> Repo.insert()

      assert CGU |> Lenra.Repo.all() |> Enum.count() == 2
      assert false == Legal.user_accepted_latest_cgu?(user.id)
    end

    test "User accepted latest CGU" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, cgu} = %{path: "a", version: 2, hash: "a"} |> CGU.new() |> Repo.insert()
      %{user_id: user.id, cgu_id: cgu.id} |> UserAcceptCGUVersion.new() |> Repo.insert()

      assert true == Legal.user_accepted_latest_cgu?(user.id)
    end

    test "User accepted CGU but it is not the latest" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, cgu} = %{path: "a", version: 2, hash: "a"} |> CGU.new() |> Repo.insert()
      %{user_id: user.id, cgu_id: cgu.id} |> UserAcceptCGUVersion.new() |> Repo.insert()
      date = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, _cgu} =
        %{path: "b", version: 3, hash: "b"}
        |> CGU.new()
        |> Ecto.Changeset.put_change(:inserted_at, date)
        |> Ecto.Changeset.put_change(:updated_at, date)
        |> Repo.insert()

      assert false == Legal.user_accepted_latest_cgu?(user.id)
    end
  end
end
