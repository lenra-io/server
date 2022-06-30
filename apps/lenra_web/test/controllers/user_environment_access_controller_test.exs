defmodule LenraWeb.UserEnvironmentAccessControllerTest do
  use LenraWeb.ConnCase, async: true

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  defp create_app(conn) do
    post(conn, Routes.apps_path(conn, :create), %{
      "name" => "test",
      "color" => "ffffff",
      "icon" => 12
    })
  end

  describe "index" do
    test "user environment access controller not authenticated", %{conn: conn} do
      conn = get(conn, Routes.user_environment_access_path(conn, :index, 0, 0))

      assert json_response(conn, 401) == %{
               "error" => "You are not authenticated"
             }
    end

    @tag auth_users: [:dev, :user, :dev, :admin]
    test "get user environment access check authorizations", %{users: [creator!, user, other_dev, admin]} do
      creator! = create_app(creator!)

      assert %{"data" => app} = json_response(creator!, 200)

      assert %{"data" => envs} = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      creator! =
        post(creator!, Routes.user_environment_access_path(creator!, :create, app["id"], env["id"]), %{
          "user_id" => Guardian.Plug.current_resource(creator!).id
        })

      assert %{} = json_response(creator!, 200)

      get_route_name = Routes.user_environment_access_path(creator!, :index, app["id"], env["id"])
      user = get(user, get_route_name)
      other_dev = get(other_dev, get_route_name)
      admin = get(admin, get_route_name)
      creator! = get(creator!, get_route_name)

      assert %{
               "data" => [%{"environment_id" => _, "user_id" => _, "email" => _}]
             } = json_response(creator!, 200)

      assert %{
               "data" => [%{"environment_id" => _, "user_id" => _, "email" => _}]
             } = json_response(admin, 200)

      assert %{
               "error" => "Forbidden"
             } = json_response(user, 403)

      assert %{
               "error" => "Forbidden"
             } = json_response(other_dev, 403)
    end
  end

  describe "create" do
    @tag auth_users: [:dev, :user, :dev, :admin]
    test "user environment access controller authenticated", %{users: [creator!, user!, other_dev!, admin!]} do
      creator! = create_app(creator!)
      assert %{"data" => app} = json_response(creator!, 200)

      assert %{"data" => envs} = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      create_user_access = Routes.user_environment_access_path(creator!, :create, app["id"], env["id"])

      creator! =
        post(creator!, create_user_access, %{
          "user_id" => Guardian.Plug.current_resource(creator!).id
        })

      admin! =
        post(admin!, create_user_access, %{
          "user_id" => Guardian.Plug.current_resource(creator!).id
        })

      user! =
        post(user!, create_user_access, %{
          "user_id" => Guardian.Plug.current_resource(creator!).id
        })

      other_dev! =
        post(other_dev!, create_user_access, %{
          "user_id" => Guardian.Plug.current_resource(creator!).id
        })

      assert %{} = json_response(creator!, 200)

      assert %{
               "error" => "user_id has already been taken"
             } ==
               json_response(admin!, 400)

      assert %{"error" => _error} = json_response(user!, 403)
      assert %{"error" => _error} = json_response(other_dev!, 403)
    end

    @tag auth_user: :dev
    test "user environment access controller authenticated but invalid params", %{conn: conn!} do
      conn! = create_app(conn!)

      assert %{"data" => app} = json_response(conn!, 200)

      assert %{"data" => envs} = json_response(get(conn!, Routes.envs_path(conn!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      conn! =
        post(conn!, Routes.user_environment_access_path(conn!, :create, app["id"], env["id"]), %{
          "user_id" => "wrong"
        })

      assert %{"error" => _error} = json_response(conn!, 400)
    end
  end

  describe "add_user_env_access_from_email" do
    @tag auth_users: [:dev, :user, :dev, :admin]
    test "successfull authenticated", %{users: [creator!, user!, other_dev!, admin!]} do
      creator! = create_app(creator!)
      assert %{"data" => app} = json_response(creator!, 200)

      assert %{"data" => envs} = json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      create_user_access = Routes.user_environment_access_path(creator!, :create, app["id"], env["id"])

      creator! =
        post(creator!, create_user_access, %{
          "email" => Guardian.Plug.current_resource(creator!).email
        })

      admin! =
        post(admin!, create_user_access, %{
          "email" => Guardian.Plug.current_resource(creator!).email
        })

      user! =
        post(user!, create_user_access, %{
          "email" => Guardian.Plug.current_resource(creator!).email
        })

      other_dev! =
        post(other_dev!, create_user_access, %{
          "email" => Guardian.Plug.current_resource(creator!).email
        })

      assert %{} = json_response(creator!, 200)

      assert %{
               "error" => "user_id has already been taken"
             } ==
               json_response(admin!, 400)

      assert %{} = json_response(user!, 403)
      assert %{} = json_response(other_dev!, 403)
    end
  end
end
