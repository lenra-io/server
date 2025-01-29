defmodule LenraWeb.UserEnvironmentRoleControllerTest do
  use LenraWeb.ConnCase, async: true

  alias Lenra.Apps

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  describe "index" do
    test "user environment role controller not authenticated", %{conn: conn} do
      conn = get(conn, Routes.user_environment_role_path(conn, :index, 0, 0, 0))

      assert json_response(conn, 401) == %{
               "message" => "No Bearer token found in Authorization header",
               "reason" => "token_not_found",
               "metadata" => %{}
             }
    end

    @tag auth_users_with_cgs: [:dev, :user, :dev, :admin]
    test "get user environment roles check authorizations", %{users: [creator!, user, other_dev, admin]} do
      %{conn: creator!, app: app} = create_app(creator!)

      assert envs = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      %{assigns: %{user: %{email: email}}} = user

      {:ok, %{inserted_user_access: user_access}} = Apps.create_user_env_access(env["id"], %{"email" => email}, nil)

      assert %{} = json_response(creator!, 200)

      get_route_name = Routes.user_environment_role_path(creator!, :index, app["id"], env["id"], user_access.id)
      user = get(user, get_route_name)
      other_dev = get(other_dev, get_route_name)
      admin = get(admin, get_route_name)
      creator! = get(creator!, get_route_name)

      assert [] = json_response(creator!, 200)

      assert [] = json_response(admin, 200)

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
    test "user environment role controller authenticated", %{users: [creator!, user!, other_dev!, admin!]} do
      %{conn: creator!, app: app} = create_app(creator!)

      assert envs = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      %{assigns: %{user: %{email: email}}} = user!

      {:ok, %{inserted_user_access: user_access}} = Apps.create_user_env_access(env["id"], %{"email" => email}, nil)

      create_user_role = Routes.user_environment_role_path(creator!, :create, app["id"], env["id"], user_access.id)

      creator! =
        post(creator!, create_user_role, %{
          "role" => "creator"
        })

      admin! =
        post(admin!, create_user_role, %{
          "role" => "admin"
        })

      user! =
        post(user!, create_user_role, %{
          "role" => "us"
        })

      other_dev! =
        post(other_dev!, create_user_role, %{
          "role" => "other"
        })

      assert %{} = json_response(creator!, 200)

      assert %{} = json_response(admin!, 200)

      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(user!, 403)
      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(other_dev!, 403)
    end

    @tag auth_users_with_cgs: [:dev]
    test "duplicated role", %{users: [creator!]} do
      %{conn: creator!, app: app} = create_app(creator!)

      assert envs = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      {:ok, %{inserted_user_access: user_access}} = Apps.create_user_env_access(env["id"], %{"email" => "test@lenra.io"}, nil)

      create_user_role = Routes.user_environment_role_path(creator!, :create, app["id"], env["id"], user_access.id)

      creator! =
        post(creator!, create_user_role, %{
          "role" => "test"
        })

      assert %{} = json_response(creator!, 200)

      creator! =
        post(creator!, create_user_role, %{
          "role" => "test"
        })

      assert %{} = json_response(creator!, 400)
    end

    @tag auth_users_with_cgs: [:dev]
    test "check role validity", %{users: [creator!]} do
      %{conn: creator!, app: app} = create_app(creator!)

      assert envs = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      {:ok, %{inserted_user_access: user_access}} = Apps.create_user_env_access(env["id"], %{"email" => "test@lenra.io"}, nil)

      create_user_role = Routes.user_environment_role_path(creator!, :create, app["id"], env["id"], user_access.id)

      valid_roles = [
        "admin",
        "dev",
        "with-dash",
        "with+plus",
        "with_underscore",
        "with.dot",
        "with:colon",
        "with@at",
        "with#hash",
        "camelCase",
        "UPPERCASE",
        "lowercase",
        "123"
      ]
      wrong_roles = [
        "",
        "user",
        "owner",
        "with space",
        "with;semicolon",
        "with*wildcard",
        "tooLongRoleNameSinceWeHaveToDefineALimitInOrderToAvoidSQLInjection",
      ]

      for role <- valid_roles do
        creator! =
          post(creator!, create_user_role, %{
            "role" => role
          })

        assert %{} = json_response(creator!, 200)
      end

      for role <- wrong_roles do
        creator! =
          post(creator!, create_user_role, %{
            "role" => role
          })

        assert %{} = json_response(creator!, 400)
      end
    end
  end
end
