defmodule UserAcceptCguServicesTest do
  use Lenra.RepoCase, async: false

  alias Lenra.{
    Cgu,
    User,
    UserAcceptCguVersionServices
  }

  @valid_cgu %{link: "Test", version: "1.0.0", hash: "test"}

  test "acceptCguVersion should succeed" do
    {:ok, %{inserted_user: user, inserted_registration_code: registration_code}} = register_john_doe()
    cgu = Cgu.new(@valid_cgu)
    {:ok, %Cgu{} = inserted_cgu} = Repo.insert(cgu)

    assert %{valid?: true} = Repo.transaction(UserAcceptCguVersionServices.acceptCguVersion(user, inserted_cgu))
  end
end
