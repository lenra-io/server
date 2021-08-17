defmodule UserServicesTest do
  use Lenra.RepoCase, async: true
  alias Lenra.{User, DevCode, UserServices}

  test "register user should succeed" do
    {:ok, %{inserted_user: user, inserted_registration_code: registration_code}} = register_john_doe()

    assert user.first_name == "John"
    assert user.last_name == "Doe"
    assert user.email == "john.doe@lenra.fr"
    assert user.role == :unverified_user

    assert String.length(registration_code.code) == 8
  end

  test "register should fail if email already exists" do
    {:ok, _} = register_john_doe()

    {:error, _step, changeset, _} = register_john_doe()

    assert not changeset.valid?

    assert changeset.errors == [
             {:email, {"has already been taken", [constraint: :unique, constraint_name: "users_email_index"]}}
           ]
  end

  test "register should fail if email malformated" do
    {:error, _step, changeset, _} = register_john_doe(%{"email" => "johnlenra.fr"})

    assert not changeset.valid?

    assert changeset.errors == [
             email: {"has invalid format", [validation: :format]}
           ]
  end

  test "register should fail if email not specified" do
    {:error, _step, changeset, _} = register_john_doe(%{"email" => ""})

    assert not changeset.valid?

    assert changeset.errors == [
             {:email, {"can't be blank", [validation: :required]}}
           ]
  end

  test "login user should succeed event with caps" do
    {:ok, _} = register_john_doe()

    {:ok, user} = UserServices.login("john.doe@lenra.fr", "Johndoe@thefirst")

    assert %User{
             first_name: "John",
             last_name: "Doe",
             email: "john.doe@lenra.fr"
           } = user
  end

  test "sign_in user should fail with wrong email" do
    {:ok, _} = register_john_doe()

    assert {:error, :email_or_password_incorrect} ==
             UserServices.login("John@Lenra.FR", "Johndoe@thefirst")
  end

  test "sign_in user should fail with wrong password" do
    {:ok, _} = register_john_doe()

    assert {:error, :email_or_password_incorrect} ==
             UserServices.login("john.doe@lenra.fr", "johndoethesecond")
  end

  test "validate dev with correct code" do
    {:ok, %{inserted_user: %User{id: user_id} = user}} = register_john_doe()

    valid_code = "fbd1ff7e-5751-4617-afaa-ef3be4cc43a6"

    assert {:ok, %{updated_user: updated_user, updated_code: updated_dev_code}} =
             UserServices.validate_dev(user, valid_code)

    assert %User{id: ^user_id, role: :dev} = updated_user
    assert %DevCode{code: ^valid_code, user_id: ^user_id} = updated_dev_code
  end

  test "validate dev with invalid uuid type" do
    {:ok, %{inserted_user: user}} = register_john_doe()

    invalid_code = "not-a-code"

    assert {:error, :invalid_uuid} = UserServices.validate_dev(user, invalid_code)
  end

  test "validate dev with invalid code" do
    {:ok, %{inserted_user: user}} = register_john_doe()

    invalid_code = "fbd1ff7e-5751-4617-afaa-ef3be4cc43a5"

    assert {:error, :invalid_code} = UserServices.validate_dev(user, invalid_code)
  end

  test "validate dev a user that is already a dev" do
    {:ok, %{inserted_user: user}} = register_john_doe(%{"role" => :dev})

    valid_code = "fbd1ff7e-5751-4617-afaa-ef3be4cc43a6"

    assert {:error, :already_dev} = UserServices.validate_dev(user, valid_code)
  end

  test "validate dev with already used code" do
    {:ok, %{inserted_user: user}} = register_john_doe()
    {:ok, %{inserted_user: user2}} = register_john_doe(%{"email" => "johndoed2@lenra.fr"})

    valid_code = "fbd1ff7e-5751-4617-afaa-ef3be4cc43a6"

    assert {:ok, _} = UserServices.validate_dev(user, valid_code)
    assert {:error, :dev_code_already_used} = UserServices.validate_dev(user2, valid_code)
  end
end
