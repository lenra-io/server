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
               "errors" => [%{"code" => 401, "message" => "You are not authenticated"}],
               "success" => false
             }
    end

    @tag auth_users: [:dev, :user, :dev, :admin]
    test "get user environment access check authorizations", %{users: [creator!, user, other_dev, admin]} do
      creator! = create_app(creator!)

      assert %{"success" => true, "data" => %{"app" => app}} = json_response(creator!, 200)

      assert %{"data" => %{"envs" => envs}, "success" => true} =
               json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      creator! =
        post(creator!, Routes.user_environment_access_path(creator!, :create, app["id"], env["id"]), %{
          "user_id" => Guardian.Plug.current_resource(creator!).id
        })

      assert %{"success" => true} = json_response(creator!, 200)

      get_route_name = Routes.user_environment_access_path(creator!, :index, app["id"], env["id"])
      user = get(user, get_route_name)
      other_dev = get(other_dev, get_route_name)
      admin = get(admin, get_route_name)
      creator! = get(creator!, get_route_name)

      assert %{
               "data" => %{
                 "environment_user_accesses" => [%{"environment_id" => _, "user_id" => _}]
               },
               "success" => true
             } = json_response(creator!, 200)

      assert %{
               "data" => %{
                 "environment_user_accesses" => [%{"environment_id" => _, "user_id" => _}]
               },
               "success" => true
             } = json_response(admin, 200)

      assert %{
               "success" => false,
               "errors" => [%{"code" => 403, "message" => "Forbidden"}]
             } = json_response(user, 403)

      assert %{
               "success" => false,
               "errors" => [%{"code" => 403, "message" => "Forbidden"}]
             } = json_response(other_dev, 403)
    end
  end

  describe "create" do
    @tag auth_users: [:dev, :user, :dev, :admin]
    test "user environment access controller authenticated", %{users: [creator!, user!, other_dev!, admin!]} do
      creator! = create_app(creator!)
      assert %{"success" => true, "data" => %{"app" => app}} = json_response(creator!, 200)

      assert %{"data" => %{"envs" => envs}, "success" => true} =
               json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

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

      assert %{"success" => true} = json_response(creator!, 200)

      assert %{
               "success" => false,
               "errors" => [
                 %{"code" => 0, "message" => "user_id has already been taken"}
               ]
             } ==
               json_response(admin!, 400)

      assert %{"success" => false} = json_response(user!, 403)
      assert %{"success" => false} = json_response(other_dev!, 403)
    end

    @tag auth_user: :dev
    test "user environment access controller authenticated but invalid params", %{conn: conn!} do
      conn! = create_app(conn!)

      assert %{"success" => true, "data" => %{"app" => app}} = json_response(conn!, 200)

      assert %{"data" => %{"envs" => envs}, "success" => true} =
               json_response(get(conn!, Routes.envs_path(conn!, :index, app["id"])), 200)

      env = Enum.at(envs, 0)

      conn! =
        post(conn!, Routes.user_environment_access_path(conn!, :create, app["id"], env["id"]), %{
          "user_id" => "wrong"
        })

      assert %{"errors" => _errors, "success" => false} = json_response(conn!, 400)
    end
  end
end
