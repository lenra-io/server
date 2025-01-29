defmodule LenraWeb.UserEnvironmentAccessControllerTest do
  use LenraWeb.ConnCase, async: true

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  describe "index" do
    test "user environment access controller not authenticated", %{conn: conn} do
      conn = get(conn, Routes.user_environment_access_path(conn, :index, 0, 0))

      assert json_response(conn, 401) == %{
               "message" => "No Bearer token found in Authorization header",
               "reason" => "token_not_found",
               "metadata" => %{}
             }
    end

    @tag auth_users_with_cgs: [:dev, :user, :dev, :admin]
    test "get user environment access check authorizations", %{users: [creator!, user, other_dev, admin]} do
      %{conn: creator!, app: app} = create_app(creator!)

      assert envs = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      %{assigns: %{user: %{email: email}}} = user

      creator! =
        post(creator!, Routes.user_environment_access_path(creator!, :create, app["id"], env["id"]), %{
          "email" => email
        })

      assert %{} = json_response(creator!, 200)

      get_route_name = Routes.user_environment_access_path(creator!, :index, app["id"], env["id"])
      user = get(user, get_route_name)
      other_dev = get(other_dev, get_route_name)
      admin = get(admin, get_route_name)
      creator! = get(creator!, get_route_name)

      assert [%{"environment_id" => _, "email" => _}] = json_response(creator!, 200)

      assert [%{"environment_id" => _, "email" => _}] = json_response(admin, 200)

      assert %{
               "message" => "Forbidden",
               "reason" => "forbidden"
             } = json_response(user, 403)

      assert %{
               "message" => "Forbidden",
               "reason" => "forbidden"
             } = json_response(other_dev, 403)
    end
  end

  describe "create" do
    @tag auth_users_with_cgs: [:dev, :user, :dev, :admin]
    test "user environment access controller authenticated", %{users: [creator!, user!, other_dev!, admin!]} do
      %{conn: creator!, app: app} = create_app(creator!)

      assert envs = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      create_user_access = Routes.user_environment_access_path(creator!, :create, app["id"], env["id"])

      creator! =
        post(creator!, create_user_access, %{
          "email" => "creator.test@lenra.io"
        })

      admin! =
        post(admin!, create_user_access, %{
          "email" => "admin.test@lenra.io"
        })

      user! =
        post(user!, create_user_access, %{
          "email" => "user.test@lenra.io"
        })

      other_dev! =
        post(other_dev!, create_user_access, %{
          "email" => "other-user.test@lenra.io"
        })

      assert %{} = json_response(creator!, 200)

      assert %{} = json_response(admin!, 200)

      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(user!, 403)
      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(other_dev!, 403)
    end
  end

  describe "add_user_env_access_from_email" do
    @tag auth_users_with_cgs: [:dev, :user, :dev, :admin]
    test "successful authenticated", %{users: [creator!, user!, other_dev!, admin!]} do
      %{conn: creator!, app: app} = create_app(creator!)

      assert envs = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      create_user_access = Routes.user_environment_access_path(creator!, :create, app["id"], env["id"])

      %{assigns: %{user: %{email: email}}} = user!

      creator! =
        post(creator!, create_user_access, %{
          "email" => email
        })

      admin! =
        post(admin!, create_user_access, %{
          "email" => email
        })

      user! =
        post(user!, create_user_access, %{
          "email" => email
        })

      other_dev! =
        post(other_dev!, create_user_access, %{
          "email" => email
        })

      assert %{} = json_response(creator!, 200)

      assert %{
               "message" => "user_id has already been taken",
               "reason" => "invalid_user_id"
             } ==
               json_response(admin!, 400)

      assert %{} = json_response(user!, 403)
      assert %{} = json_response(other_dev!, 403)
    end
  end
end
