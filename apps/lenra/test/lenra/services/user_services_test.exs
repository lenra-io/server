defmodule UserServicesTest do
  use Lenra.RepoCase, async: false
  use Bamboo.Test, shared: true

  alias Lenra.Accounts

  alias Lenra.Accounts.{
    LostPasswordCode,
    User
  }

  alias Lenra.EmailService

  test "register user should succeed" do
    {:ok, %{inserted_user: user, inserted_registration_code: registration_code}} = register_john_doe()

    assert user.first_name == "John"
    assert user.last_name == "Doe"
    assert user.email == "john.doe@lenra.fr"
    assert user.role == :unverified_user

    assert String.length(registration_code.code) == 8
  end

  test "send email after registration" do
    {:ok, %{inserted_user: user, inserted_registration_code: registration_code}} = register_john_doe()

    email = EmailService.create_welcome_email(user.email, registration_code.code)

    assert_delivered_email(email)
  end

  test "send email for a password recovery" do
    {:ok, %{inserted_user: user}} = register_john_doe()

    {:ok, %{password_code: %LostPasswordCode{} = password_code}} = Accounts.send_lost_password_code(user)

    email = EmailService.create_recovery_email(user.email, password_code.code)
    assert_delivered_email(email)
  end

  test "register should fail if email already exists" do
    {:ok, _value} = register_john_doe()

    {:error, _step, changeset, _changes_so_far} = register_john_doe()

    assert not changeset.valid?

    assert changeset.errors == [
             {:email, {"has already been taken", [constraint: :unique, constraint_name: "users_email_index"]}}
           ]
  end

  test "register should fail if email malformated" do
    {:error, _step, changeset, _changes_so_far} = register_john_doe(%{"email" => "johnlenra.fr"})

    assert not changeset.valid?

    assert changeset.errors == [
             email: {"has invalid format", [validation: :format]}
           ]
  end

  test "register should fail if email not specified" do
    {:error, _step, changeset, _changes_so_far} = register_john_doe(%{"email" => ""})

    assert not changeset.valid?

    assert changeset.errors == [
             {:email, {"can't be blank", [validation: :required]}}
           ]
  end

  test "login user should succeed event with caps" do
    {:ok, _} = register_john_doe()

    {:ok, user} = Accounts.login_user("john.doe@lenra.fr", "Johndoe@thefirst")

    assert %User{
             first_name: "John",
             last_name: "Doe",
             email: "john.doe@lenra.fr"
           } = user
  end

  test "sign_in user should fail with wrong email" do
    {:ok, _} = register_john_doe()

    assert {:error, %LenraCommon.Errors.BusinessError{reason: :incorrect_email_or_password}} =
             Accounts.login_user("John@Lenra.FR", "Johndoe@thefirst")
  end

  test "sign_in user should fail with wrong password" do
    {:ok, _} = register_john_doe()

    assert {:error, %LenraCommon.Errors.BusinessError{reason: :incorrect_email_or_password}} =
             Accounts.login_user("john.doe@lenra.fr", "johndoethesecond")
  end

  test "The password code should be deleted after password modification" do
    {:ok, %{inserted_user: user}} = register_john_doe()
    {:ok, _} = Accounts.send_lost_password_code(user)
    user! = Repo.preload(user, [:password_code])
    password_code = user!.password_code.code
    assert not is_nil(password_code)

    assert {:ok, _} =
             Accounts.update_user_password_with_code(user!, %{
               "password" => "MyNewPassword42!",
               "code" => password_code
             })

    # Force reload the password code
    user! = Repo.preload(user!, [:password_code], force: true)
    assert is_nil(user!.password_code)
  end
end
