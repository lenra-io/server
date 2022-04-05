defmodule Lenra.CguSerciceTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Cgu, CguService}

  @valid_cgu1 %{link: "Test", version: "1.0.0", hash: "test"}
  @valid_cgu2 %{link: "Test1", version: "1.1.0", hash: "Test1"}
  @valid_cgu3 %{link: "Test2", version: "1.2.0", hash: "Test2"}
  @valid_cgu4 %{link: "Test3", version: "1.3.0", hash: "Test3"}

  describe "get_latest_cgu" do
    test "insert 2 cgu and check if the service take the latest" do
      {:ok, %Cgu{} = _inserted_cgu} = @valid_cgu1 |> Cgu.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, %Cgu{} = inserted_cgu1} =
        @valid_cgu2
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      assert {:ok, inserted_cgu1} == CguService.get_latest_cgu()
    end

    test "insert 4 cgu and check if the service take the latest" do
      {:ok, %Cgu{} = _inserted_cgu} = @valid_cgu1 |> Cgu.new() |> Repo.insert()

      date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, %Cgu{} = _inserted_cgu1} =
        @valid_cgu2
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date1)
        |> Repo.insert()

      date2 = DateTime.utc_now() |> DateTime.add(8, :second) |> DateTime.truncate(:second)

      {:ok, %Cgu{} = _inserted_cgu2} =
        @valid_cgu3
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date2)
        |> Repo.insert()

      date3 = DateTime.utc_now() |> DateTime.add(12, :second) |> DateTime.truncate(:second)

      {:ok, %Cgu{} = inserted_cgu3} =
        @valid_cgu4
        |> Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date3)
        |> Repo.insert()

      assert {:ok, inserted_cgu3} == CguService.get_latest_cgu()
    end
  end

  describe "user_accepted_latest_cgu?" do
    test "No CGU in database" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

      assert true == Lenra.CguService.user_accepted_latest_cgu?(user.id)
    end

    test "User did not accept CGU" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      %{link: "a", version: "1.0.0", hash: "a"} |> Lenra.Cgu.new() |> Repo.insert()

      assert Lenra.Cgu |> Lenra.Repo.all() |> Enum.count() == 1
      assert false == Lenra.CguService.user_accepted_latest_cgu?(user.id)
    end

    test "User accepted latest CGU" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, cgu} = %{link: "a", version: "1.0.0", hash: "a"} |> Lenra.Cgu.new() |> Repo.insert()
      %{user_id: user.id, cgu_id: cgu.id} |> Lenra.UserAcceptCguVersion.new() |> Repo.insert()

      assert true == Lenra.CguService.user_accepted_latest_cgu?(user.id)
    end

    test "User accepted CGU but it is not the latest" do
      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()
      {:ok, cgu} = %{link: "a", version: "1.0.0", hash: "a"} |> Lenra.Cgu.new() |> Repo.insert()
      %{user_id: user.id, cgu_id: cgu.id} |> Lenra.UserAcceptCguVersion.new() |> Repo.insert()
      date = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

      {:ok, _cgu} =
        %{link: "b", version: "2.0.0", hash: "b"}
        |> Lenra.Cgu.new()
        |> Ecto.Changeset.put_change(:inserted_at, date)
        |> Ecto.Changeset.put_change(:updated_at, date)
        |> Repo.insert()

      assert false == Lenra.CguService.user_accepted_latest_cgu?(user.id)
    end
  end
end
