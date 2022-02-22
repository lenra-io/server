defmodule LenraWeb.EnvironmentControllerTest do
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
    test "environment controller not authenticated", %{conn: conn} do
      conn = get(conn, Routes.envs_path(conn, :index, 0))

      assert json_response(conn, 401) == %{
               "errors" => [%{"code" => 401, "message" => "You are not authenticated"}],
               "success" => false
             }
    end

    @tag auth_users: [:dev, :user, :dev, :admin]
    test "get environment check authorizations", %{users: [creator!, user, other_dev, admin]} do
      creator! = create_app(creator!)

      assert %{"success" => true, "data" => %{"app" => app}} = json_response(creator!, 200)

      creator! =
        post(creator!, Routes.envs_path(creator!, :create, app["id"]), %{
          "name" => "test",
          "is_ephemeral" => false,
          "is_public" => false
        })

      assert %{"success" => true} = json_response(creator!, 200)

      get_route_name = Routes.envs_path(creator!, :index, app["id"])
      user = get(user, get_route_name)
      other_dev = get(other_dev, get_route_name)
      admin = get(admin, get_route_name)
      creator! = get(creator!, get_route_name)

      assert %{
               "data" => %{
                 "envs" => [
                   %{
                     "is_ephemeral" => false,
                     "name" => "live",
                     "application_id" => _,
                     "creator_id" => _,
                     "deployed_build_id" => _,
                     "id" => _
                   },
                   %{
                     "is_ephemeral" => false,
                     "name" => "test",
                     "application_id" => _,
                     "creator_id" => _,
                     "deployed_build_id" => _,
                     "id" => _
                   }
                 ]
               },
               "success" => true
             } = json_response(creator!, 200)

      assert %{
               "data" => %{
                 "envs" => [
                   %{
                     "is_ephemeral" => false,
                     "name" => "live",
                     "application_id" => _,
                     "creator_id" => _,
                     "deployed_build_id" => _,
                     "id" => _
                   },
                   %{
                     "is_ephemeral" => false,
                     "name" => "test",
                     "application_id" => _,
                     "creator_id" => _,
                     "deployed_build_id" => _,
                     "id" => _
                   }
                 ]
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

  describe "update" do
    @tag auth_users: [:dev, :user, :dev, :admin]
    test "environment controller authenticated", %{users: [creator!, user!, other_dev!, admin!]} do
      creator! = create_app(creator!)
      assert %{"success" => true, "data" => %{"app" => app}} = json_response(creator!, 200)

      %{"success" => true, "data" => %{"envs" => [env]}} =
        json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      update_env_path = Routes.envs_path(creator!, :update, app["id"], env["id"])

      creator! =
        patch(creator!, update_env_path, %{
          "is_public" => true
        })

      assert %{"success" => true, "data" => %{"envs" => [%{"is_public" => true}]}} =
               json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      admin! =
        patch(admin!, update_env_path, %{
          "is_public" => false
        })

      assert %{"success" => true, "data" => %{"envs" => [%{"is_public" => false}]}} =
               json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      user! =
        patch(user!, update_env_path, %{
          "is_public" => true
        })

      assert %{"success" => true, "data" => %{"envs" => [%{"is_public" => false}]}} =
               json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      other_dev! =
        patch(other_dev!, update_env_path, %{
          "is_public" => true
        })

      assert %{"success" => true, "data" => %{"envs" => [%{"is_public" => false}]}} =
               json_response(get(creator!, Routes.envs_path(creator!, :index, app["id"])), 200)

      assert %{"success" => true} = json_response(creator!, 200)
      assert %{"success" => true} = json_response(admin!, 200)
      assert %{"success" => false} = json_response(user!, 403)
      assert %{"success" => false} = json_response(other_dev!, 403)
    end
  end

  describe "create" do
    @tag auth_users: [:dev, :user, :dev, :admin]
    test "environment controller authenticated", %{users: [creator!, user!, other_dev!, admin!]} do
      creator! = create_app(creator!)
      assert %{"success" => true, "data" => %{"app" => app}} = json_response(creator!, 200)

      create_env_path = Routes.envs_path(creator!, :create, app["id"])

      creator! =
        post(creator!, create_env_path, %{
          "name" => "test_creator",
          "is_ephemeral" => false,
          "is_public" => false
        })

      admin! =
        post(admin!, create_env_path, %{
          "name" => "test_admin",
          "is_ephemeral" => false,
          "is_public" => false
        })

      user! =
        post(user!, create_env_path, %{
          "name" => "test_user",
          "is_ephemeral" => false,
          "is_public" => false
        })

      other_dev! =
        post(other_dev!, create_env_path, %{
          "name" => "test_other_dev",
          "is_ephemeral" => false,
          "is_public" => false
        })

      assert %{"success" => true} = json_response(creator!, 200)
      assert %{"success" => true} = json_response(admin!, 200)
      assert %{"success" => false} = json_response(user!, 403)
      assert %{"success" => false} = json_response(other_dev!, 403)
    end

    @tag auth_user: :dev
    test "environment controller authenticated but invalid params", %{conn: conn!} do
      conn! = create_app(conn!)

      assert %{"success" => true, "data" => %{"app" => app}} = json_response(conn!, 200)

      conn! =
        post(conn!, Routes.envs_path(conn!, :create, app["id"]), %{
          "name" => 1234,
          "is_ephemeral" => "false",
          "is_public" => false
        })

      assert %{"errors" => _errors, "success" => false} = json_response(conn!, 400)
    end
  end
end
