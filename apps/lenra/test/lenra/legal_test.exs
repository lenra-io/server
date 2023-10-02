defmodule Lenra.LegalTest do
  use Lenra.RepoCase, async: true

  alias Lenra.Errors.BusinessError
  alias Lenra.Legal
  alias Lenra.Legal.{CGS, UserAcceptCGSVersion}

  @valid_cgs1 %{path: "Test", version: 2, hash: "test"}
  @valid_cgs2 %{path: "Test1", version: 3, hash: "Test1"}
  @valid_cgs3 %{path: "Test2", version: 4, hash: "Test2"}
  @valid_cgs4 %{path: "Test3", version: 5, hash: "Test3"}

  describe "get_latest_cgs" do
    test "insert 2 cgs and check if the service take the latest" do
      {:ok, %CGS{} = _inserted_cgs} = @valid_cgs1 |> CGS.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, %CGS{} = inserted_cgs1} =
        @valid_cgs2
        |> CGS.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      assert {:ok, inserted_cgs1} == Legal.get_latest_cgs()
    end

    test "insert 4 cgs and check if the service take the latest" do
      {:ok, %CGS{} = _inserted_cgs} = @valid_cgs1 |> CGS.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, %CGS{} = _inserted_cgs1} =
        @valid_cgs2
        |> CGS.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      date2 = DateTime.utc_now() |> DateTime.add(8, :second) |> DateTime.truncate(:second)

      {:ok, %CGS{} = _inserted_cgs2} =
        @valid_cgs3
        |> CGS.new()
        |> Ecto.Changeset.put_change(:inserted_at, date2)
        |> Repo.insert()

      date3 = DateTime.utc_now() |> DateTime.add(12, :second) |> DateTime.truncate(:second)

      {:ok, %CGS{} = inserted_cgs3} =
        @valid_cgs4
        |> CGS.new()
        |> Ecto.Changeset.put_change(:inserted_at, date3)
        |> Repo.insert()

      assert {:ok, inserted_cgs3} == Legal.get_latest_cgs()
    end
  end

  describe "accept" do
    setup do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

      %{user: user}
    end

    test "existing cgs", %{user: user} do
      {:ok, cgs} = Repo.insert(CGS.new(%{path: "test.html", hash: "a", version: 2}))
      assert {:ok, %{accepted_cgs: _cgs}} = Legal.accept_cgs(cgs.id, user.id)
    end

    test "not latest cgs", %{user: user} do
      {:ok, cgs} = Repo.insert(CGS.new(%{path: "test.html", hash: "a", version: 2}))

      Repo.insert(
        %{path: "test2.html", hash: "b", version: 3}
        |> CGS.new()
        |> Ecto.Changeset.put_change(
          :inserted_at,
          DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)
        )
      )

      assert BusinessError.not_latest_cgs_tuple() == Legal.accept_cgs(cgs.id, user.id)
    end

    test "not existing user", %{user: _user} do
      {:ok, cgs} = Repo.insert(CGS.new(%{path: "test.html", hash: "a", version: 2}))

      assert {:error, :accepted_cgs, %{errors: [user_id: {"does not exist", _constraints}]}, _any} =
               Legal.accept_cgs(cgs.id, -1)
    end

    test "latest cgs", %{user: user} do
      Repo.insert(CGS.new(%{path: "test.html", hash: "a", version: 2}))

      {:ok, cgs} =
        Repo.insert(
          %{path: "test2.html", hash: "b", version: 3}
          |> CGS.new()
          |> Ecto.Changeset.put_change(
            :inserted_at,
            DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)
          )
        )

      assert {:ok, %{accepted_cgs: _cgs}} = Legal.accept_cgs(cgs.id, user.id)
    end
  end

  describe "user_accepted_latest_cgs?" do
    test "No CGS in database" do
      Repo.delete_all(from(CGS))
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

      assert true == Legal.user_accepted_latest_cgs?(user.id)
    end

    test "User did not accept CGS" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      %{path: "a", version: 2, hash: "a"} |> CGS.new() |> Repo.insert()

      assert CGS |> Lenra.Repo.all() |> Enum.count() == 2
      assert false == Legal.user_accepted_latest_cgs?(user.id)
    end

    test "User accepted latest CGS" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, cgs} = %{path: "a", version: 2, hash: "a"} |> CGS.new() |> Repo.insert()
      %{user_id: user.id, cgs_id: cgs.id} |> UserAcceptCGSVersion.new() |> Repo.insert()

      assert true == Legal.user_accepted_latest_cgs?(user.id)
    end

    test "User accepted CGS but it is not the latest" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, cgs} = %{path: "a", version: 2, hash: "a"} |> CGS.new() |> Repo.insert()
      %{user_id: user.id, cgs_id: cgs.id} |> UserAcceptCGSVersion.new() |> Repo.insert()
      date = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, _cgs} =
        %{path: "b", version: 3, hash: "b"}
        |> CGS.new()
        |> Ecto.Changeset.put_change(:inserted_at, date)
        |> Ecto.Changeset.put_change(:updated_at, date)
        |> Repo.insert()

      assert false == Legal.user_accepted_latest_cgs?(user.id)
    end
  end
end
