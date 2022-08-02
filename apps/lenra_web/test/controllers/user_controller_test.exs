defmodule LenraWeb.UserControllerTest do
  @moduledoc """
    Test the `LenraWeb.UserControllerTest` module
  """
  use LenraWeb.ConnCase
  use Bamboo.Test, shared: true

  alias Lenra.Accounts.{LostPasswordCode, User}
  alias Lenra.Repo

  @john_doe_user_params %{
    "first_name" => "John",
    "last_name" => "Doe",
    "email" => "john.doe@lenra.fr",
    "password" => "Johndoe@thefirst",
    "password_confirmation" => "Johndoe@thefirst"
  }

  test "register test", %{conn: conn} do
    conn = post(conn, Routes.user_path(conn, :register, @john_doe_user_params))

    assert %{"data" => _data} = json_response(conn, 200)

    assert Enum.any?(conn.resp_headers, fn element -> "access_token" in Tuple.to_list(element) end)
  end

  test "register error test", %{conn: conn} do
    conn =
      post(
        conn,
        Routes.user_path(conn, :register, %{
          "first_name" => "John",
          "last_name" => "Doe",
          "email" => "john.doelenra.fr",
          "password" => "Johndoe@thefirst",
          "password_confirmation" => "Johndoe@thefirst"
        })
      )

    assert %{
             "message" => "email has invalid format",
             "reason" => "invalid_email"
           } = json_response(conn, 400)
  end

  test "register password format error test", %{conn: conn} do
    conn =
      post(
        conn,
        Routes.user_path(conn, :register, %{
          "first_name" => "John",
          "last_name" => "Doe",
          "email" => "john.doe@lenra.fr",
          "password" => "Johndoethefirst",
          "password_confirmation" => "Johndoethefirst"
        })
      )

    assert %{
             "message" => "password has invalid format",
             "reason" => "invalid_password"
           } = json_response(conn, 400)
  end

  test "login test", %{conn: conn} do
    post(conn, Routes.user_path(conn, :register, @john_doe_user_params))

    conn =
      post(
        conn,
        Routes.user_path(conn, :login, %{
          "email" => "john.doe@lenra.fr",
          "password" => @john_doe_user_params["password"]
        })
      )

    assert %{"data" => _data} = json_response(conn, 200)

    assert Enum.any?(conn.resp_headers, fn element -> "access_token" in Tuple.to_list(element) end)
  end

  test "login incorrect email or password test", %{conn: conn} do
    post(conn, Routes.user_path(conn, :register, @john_doe_user_params))

    conn =
      post(
        conn,
        Routes.user_path(conn, :login, %{
          "email" => "john.doe@lenra.fr",
          "password" => "incorrect"
        })
      )

    assert %{"message" => "Incorrect email or password", "reason" => "incorrect_email_or_password"} =
             json_response(conn, 400)
  end

  test "refresh not authenticated test", %{conn: conn} do
    conn = post(conn, Routes.user_path(conn, :refresh_token))

    assert %{
             "message" => "You are not authenticated",
             "reason" => "unauthenticated"
           } = json_response(conn, 401)
  end

  test "refresh authenticated test", %{conn: conn} do
    conn_register = post(conn, Routes.user_path(conn, :register, @john_doe_user_params))
    Repo.delete_all(Lenra.Legal.CGU)
    conn = post(conn_register, Routes.user_path(conn_register, :refresh_token))

    assert %{"data" => _data} = json_response(conn, 200)

    assert Enum.any?(conn.resp_headers, fn element -> "access_token" in Tuple.to_list(element) end)
  end

  test "logout test", %{conn: conn!} do
    conn! = post(conn!, Routes.user_path(conn!, :register, @john_doe_user_params))

    conn! = post(conn!, Routes.user_path(conn!, :logout))

    assert %{} = json_response(conn!, 200)
  end

  # send verification email disabled
  # test "code verification test", %{conn: conn} do
  #  conn = post(conn, Routes.user_path(conn, :register, @john_doe_user_params))
  #  assert_receive({:delivered_email, _email})
  #
  #  email = @john_doe_user_params["email"]
  #  user = Repo.get_by(User, email: email)
  #
  #  user = Repo.preload(user, :registration_code)
  #
  #  conn =
  #    post(
  #      conn,
  #      Routes.user_path(conn, :validate_user, %{"code" => user.registration_code.code})
  #    )
  #
  #  assert %{"data" => data, "success" => true} = json_response(conn, 200)
  #  assert Map.has_key?(data, "access_token")
  # end

  test "code verification error test", %{conn: conn!} do
    conn! = post(conn!, Routes.user_path(conn!, :register, @john_doe_user_params))

    conn! = post(conn!, Routes.user_path(conn!, :validate_user, %{"code" => "12345678"}))

    assert %{"message" => "No such registration code", "reason" => "no_such_registration_code"} =
             json_response(conn!, 400)
  end

  @tag :auth_user_with_cgu
  test "change password test", %{conn: conn} do
    new_password = "New@password"

    conn2 =
      put(
        conn,
        Routes.user_path(conn, :change_password, %{
          "old_password" => "Johndoe@thefirst",
          "password" => new_password,
          "password_confirmation" => new_password
        })
      )

    assert %{} = json_response(conn2, 200)

    conn =
      post(
        conn,
        Routes.user_path(conn, :login, %{
          "email" => "john.doe@lenra.fr",
          "password" => new_password
        })
      )

    assert %{"data" => _data} = json_response(conn, 200)

    assert Enum.any?(conn.resp_headers, fn element -> "access_token" in Tuple.to_list(element) end)
  end

  @tag :auth_user_with_cgu
  test "change password error test", %{conn: conn} do
    conn =
      put(
        conn,
        Routes.user_path(conn, :change_password, %{
          "old_password" => "Johndoe@thefirst",
          "password" => "Johndoe@thefirst",
          "password_confirmation" => "Johndoe@thefirst"
        })
      )

    assert %{
             "message" => "Your password cannot be equal to the last 3.",
             "reason" => "password_already_used"
           } = json_response(conn, 400)
  end

  @tag :auth_user
  test "change lost password test", %{conn: conn!} do
    new_password = "New@password"

    conn! =
      post(
        conn!,
        Routes.user_path(conn!, :send_lost_password_code, %{
          "email" => @john_doe_user_params["email"]
        })
      )

    user = Repo.get_by(User, email: @john_doe_user_params["email"])
    password_code = Repo.get_by(LostPasswordCode, user_id: user.id)

    conn! =
      put(
        conn!,
        Routes.user_path(conn!, :change_lost_password, %{
          "email" => @john_doe_user_params["email"],
          "code" => password_code.code,
          "password" => new_password,
          "password_confirmation" => new_password
        })
      )

    conn! =
      post(
        conn!,
        Routes.user_path(conn!, :login, %{
          "email" => @john_doe_user_params["email"],
          "password" => new_password
        })
      )

    assert %{"data" => _data} = json_response(conn!, 200)

    assert Enum.any?(conn!.resp_headers, fn element ->
             "access_token" in Tuple.to_list(element)
           end)
  end

  @tag :auth_user
  test "Using lost password code twice should fail the second time", %{conn: conn} do
    new_password = "New@password42"
    new_password2 = "New@password1337"

    # Ask for a lost password code
    conn! =
      post(
        conn,
        Routes.user_path(conn, :send_lost_password_code, %{
          "email" => @john_doe_user_params["email"]
        })
      )

    # Retrive the code (not returned by the controller)
    user = Repo.get_by(User, email: @john_doe_user_params["email"])
    password_code = Repo.get_by(LostPasswordCode, user_id: user.id)

    # Change password first time
    conn! =
      put(
        conn!,
        Routes.user_path(conn!, :change_lost_password, %{
          "email" => @john_doe_user_params["email"],
          "code" => password_code.code,
          "password" => new_password,
          "password_confirmation" => new_password
        })
      )

    # First one should succeed
    assert %{} = json_response(conn!, 200)

    # Change password a second time with another password but the same code
    conn! =
      put(
        conn!,
        Routes.user_path(conn!, :change_lost_password, %{
          "email" => @john_doe_user_params["email"],
          "code" => password_code.code,
          "password" => new_password2,
          "password_confirmation" => new_password2
        })
      )

    # Second one should fail
    assert %{} = json_response(conn!, 400)
  end

  test "change lost password wrong email test", %{conn: conn} do
    post(conn, Routes.user_path(conn, :register, @john_doe_user_params))

    conn = post(conn, Routes.user_path(conn, :send_lost_password_code, %{email: "wrong@email.me"}))

    assert %{} = json_response(conn, 200)
  end

  test "change lost password error code test", %{conn: conn} do
    post(conn, Routes.user_path(conn, :register, @john_doe_user_params))

    post(conn, Routes.user_path(conn, :send_lost_password_code, @john_doe_user_params))

    conn =
      put(
        conn,
        Routes.user_path(conn, :change_lost_password, %{
          "email" => @john_doe_user_params["email"],
          "code" => "00000000",
          "password" => "Johndoe@thefirst",
          "password_confirmation" => "Johndoe@thefirst"
        })
      )

    assert %{
             "message" => "No such password lost code",
             "reason" => "no_such_password_code"
           } = json_response(conn, 400)
  end

  test "change lost password error password test", %{conn: conn} do
    %{assigns: %{data: user}} = post(conn, Routes.user_path(conn, :register, @john_doe_user_params))

    post(conn, Routes.user_path(conn, :send_lost_password_code, @john_doe_user_params))

    password_code = Repo.get_by(LostPasswordCode, user_id: user.id)

    conn =
      put(
        conn,
        Routes.user_path(conn, :change_lost_password, %{
          "email" => @john_doe_user_params["email"],
          "code" => password_code.code,
          "password" => "Johndoe@thefirst",
          "password_confirmation" => "Johndoe@thefirst"
        })
      )

    assert %{
             "message" => "Your password cannot be equal to the last 3.",
             "reason" => "password_already_used"
           } = json_response(conn, 400)
  end

  @tag :auth_user
  test "change password code 4 time with password 1 test", %{conn: conn!} do
    Repo.delete_all("cgu")
    new_password = "Newpassword@"
    new_password_2 = "Newpassword@2"
    new_password_3 = "Newpassword@3"

    conn! =
      put(
        conn!,
        Routes.user_path(conn!, :change_password, %{
          "old_password" => "johndoethefirst",
          "password" => new_password,
          "password_confirmation" => new_password
        })
      )

    conn! =
      put(
        conn!,
        Routes.user_path(conn!, :change_password, %{
          "old_password" => new_password,
          "password" => new_password_2,
          "password_confirmation" => new_password_2
        })
      )

    conn! =
      put(
        conn!,
        Routes.user_path(conn!, :change_password, %{
          "old_password" => new_password_2,
          "password" => new_password_3,
          "password_confirmation" => new_password_3
        })
      )

    conn! =
      put(
        conn!,
        Routes.user_path(conn!, :change_password, %{
          "old_password" => new_password_3,
          "password" => "Johndoe@thefirst",
          "password_confirmation" => "Johndoe@thefirst"
        })
      )

    conn! =
      post(
        conn!,
        Routes.user_path(conn!, :login, %{
          "email" => "john.doe@lenra.fr",
          "password" => "Johndoe@thefirst"
        })
      )

    assert %{"data" => _data} = json_response(conn!, 200)

    assert Enum.any?(conn!.resp_headers, fn element ->
             "access_token" in Tuple.to_list(element)
           end)
  end

  @tag :auth_user_with_cgu
  test "validate dev user", %{conn: conn} do
    valid_code = "fbd1ff7e-5751-4617-afaa-ef3be4cc43a6"

    conn = put(conn, Routes.user_path(conn, :validate_dev, %{"code" => valid_code}))

    assert %{} = json_response(conn, 200)
  end

  @tag :auth_user_with_cgu
  test "validate dev user invalid uuid", %{conn: conn} do
    invalid_code = "not-a-uuid"

    conn = put(conn, Routes.user_path(conn, :validate_dev, %{"code" => invalid_code}))

    assert %{
             "message" => "The code is not a valid UUID",
             "reason" => "invalid_uuid"
           } = json_response(conn, 400)
  end

  @tag :auth_user_with_cgu
  test "validate dev user invalid code", %{conn: conn} do
    invalid_code = "fbd1ff7e-5751-4617-afaa-ef3be4cc43a5"

    conn = put(conn, Routes.user_path(conn, :validate_dev, %{"code" => invalid_code}))

    assert %{
             "message" => "The code is invalid",
             "reason" => "invalid_code"
           } = json_response(conn, 400)
  end

  @tag auth_user_with_cgu: :dev
  test "validate dev user already dev", %{conn: conn} do
    invalid_code = "fbd1ff7e-5751-4617-afaa-ef3be4cc43a5"

    conn = put(conn, Routes.user_path(conn, :validate_dev, %{"code" => invalid_code}))

    assert %{
             "message" => "You are already a dev",
             "reason" => "already_dev"
           } = json_response(conn, 400)
  end

  @tag auth_users_with_cgu: [:user, :user]
  test "validate dev code already used", %{users: [user1, user2]} do
    valid_code = "fbd1ff7e-5751-4617-afaa-ef3be4cc43a6"

    user1 = put(user1, Routes.user_path(user1, :validate_dev, %{"code" => valid_code}))

    assert %{} = json_response(user1, 200)

    user2 = put(user1, Routes.user_path(user2, :validate_dev, %{"code" => valid_code}))

    assert %{
             "message" => "You are already a dev",
             "reason" => "already_dev"
           } ==
             json_response(user2, 400)
  end
end
