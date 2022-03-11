defmodule Lenra.UserAcceptCguServicesTest do
  use Lenra.RepoCase, async: false

  alias Lenra.{
    Cgu,
    UserAcceptCguVersion,
    UserAcceptCguVersionServices
  }

  @valid_cgu1 %{link: "Test", version: "2.0.0", hash: "test"}

  test "acceptCguVersion should succeed" do
    {:ok, %{inserted_user: user}} = register_john_doe()
    date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

    {:ok, %Cgu{} = inserted_cgu} =
      @valid_cgu1
      |> Cgu.new()
      |> Ecto.Changeset.put_change(:inserted_at, date1)
      |> Repo.insert()

    assert {:ok, %{inserted_user_accept_cgu_version: %UserAcceptCguVersion{}}} =
             UserAcceptCguVersionServices.create(user, inserted_cgu)
  end

  test "cgu_id have to be the same in the DB and before the insert" do
    {:ok, %{inserted_user: user, inserted_accept_cgu: inserted_accept_cgu}} = register_john_doe()

    {:ok, inserted_cgu} = Repo.get(Cgu)

    UserAcceptCguVersionServices.create(user, inserted_cgu)

    query = from(u in "user_accept_cgu_versions", select: u.cgu_id)
    assert Repo.all(query) == [inserted_cgu.id]
  end

  test "user_id have to be the same in the DB and before the insert" do
    {:ok, %{inserted_user: user}} = register_john_doe()
    date1 = DateTime.utc_now() |> DateTime.add(4, :second) |> DateTime.truncate(:second)

    {:ok, %Cgu{} = inserted_cgu} =
      @valid_cgu1
      |> Cgu.new()
      |> Ecto.Changeset.put_change(:inserted_at, date1)
      |> Repo.insert()

    UserAcceptCguVersionServices.create(user, inserted_cgu)

    query = from(u in "user_accept_cgu_versions", select: u.user_id)
    assert Repo.all(query) == [user.id]
  end
end
