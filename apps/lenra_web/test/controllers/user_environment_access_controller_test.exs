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

  # describe "create" do
  #   @tag auth_users: [:dev, :user, :dev, :admin]
  #   test "environment controller authenticated", %{users: [creator!, user!, other_dev!, admin!]} do
  #     creator! = create_app(creator!)
  #     assert %{"success" => true, "data" => %{"app" => app}} = json_response(creator!, 200)

  #     create_env_path = Routes.envs_path(creator!, :create, app["id"])

  #     creator! =
  #       post(creator!, create_env_path, %{
  #         "name" => "test_creator",
  #         "is_ephemeral" => false
  #       })

  #     admin! =
  #       post(admin!, create_env_path, %{
  #         "name" => "test_admin",
  #         "is_ephemeral" => false
  #       })

  #     user! =
  #       post(user!, create_env_path, %{
  #         "name" => "test_user",
  #         "is_ephemeral" => false
  #       })

  #     other_dev! =
  #       post(other_dev!, create_env_path, %{
  #         "name" => "test_other_dev",
  #         "is_ephemeral" => false
  #       })

  #     assert %{"success" => true} = json_response(creator!, 200)
  #     assert %{"success" => true} = json_response(admin!, 200)
  #     assert %{"success" => false} = json_response(user!, 403)
  #     assert %{"success" => false} = json_response(other_dev!, 403)
  #   end

  #   @tag auth_user: :dev
  #   test "environment controller authenticated but invalid params", %{conn: conn!} do
  #     conn! = create_app(conn!)

  #     assert %{"success" => true, "data" => %{"app" => app}} = json_response(conn!, 200)

  #     conn! =
  #       post(conn!, Routes.envs_path(conn!, :create, app["id"]), %{
  #         "name" => 1234,
  #         "is_ephemeral" => "false"
  #       })

  #     assert %{"errors" => _errors, "success" => false} = json_response(conn!, 400)
  #   end
  # end
end
