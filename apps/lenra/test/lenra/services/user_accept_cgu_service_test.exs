defmodule UserAcceptCguServicesTest do
  use Lenra.RepoCase, async: false

  alias Lenra.{
    Cgu,
    UserAcceptCguVersion,
    UserAcceptCguVersionServices
  }

  @valid_cgu %{link: "Test", version: "1.0.0", hash: "test"}

  test "acceptCguVersion should succeed" do
    {:ok, %{inserted_user: user}} = register_john_doe()
    cgu = Cgu.new(@valid_cgu)
    {:ok, %Cgu{} = inserted_cgu} = Repo.insert(cgu)

    assert {:ok, %{inserted_user_accept_cgu_version: %UserAcceptCguVersion{}}} =
             UserAcceptCguVersionServices.create(user, inserted_cgu)
  end

  test "cgu_id have to be the same in the DB and before the insert" do
    {:ok, %{inserted_user: user}} = register_john_doe()
    cgu = Cgu.new(@valid_cgu)
    {:ok, %Cgu{} = inserted_cgu} = Repo.insert(cgu)

    UserAcceptCguVersionServices.create(user, inserted_cgu)

    query = from(u in "user_accept_cgu_versions", select: u.cgu_id)
    assert Repo.all(query) == [inserted_cgu.id]
  end

  test "user_id have to be the same in the DB and before the insert" do
    {:ok, %{inserted_user: user}} = register_john_doe()
    cgu = Cgu.new(@valid_cgu)
    {:ok, %Cgu{} = inserted_cgu} = Repo.insert(cgu)

    UserAcceptCguVersionServices.create(user, inserted_cgu)

    query = from(u in "user_accept_cgu_versions", select: u.user_id)
    assert Repo.all(query) == [user.id]
  end
end
