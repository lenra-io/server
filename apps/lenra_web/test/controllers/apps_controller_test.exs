defmodule LenraWeb.AppsControllerTest do
  use LenraWeb.ConnCase, async: false

  alias Lenra.Apps.App
  alias Lenra.Repo

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  defp create_app_test(conn) do
    post(
      conn,
      Routes.apps_path(conn, :create, %{
        "name" => "test",
        "color" => "ffffff",
        "icon" => 31,
        "repository" => "http://repository.com/link.git",
        "repository_branch" => "master"
      })
    )
  end

  describe "index" do
    test "apps controller not authenticated", %{conn: conn} do
      conn = get(conn, Routes.apps_path(conn, :index))

      assert json_response(conn, 401) == %{
               "message" => "No Bearer token found in Authorization header",
               "reason" => "token_not_found",
               "metadata" => %{}
             }
    end

    @tag auth_user_with_cgs: :dev
    test "apps controller authenticated", %{conn: conn!} do
      conn! = create_app_test(conn!)
      assert %{} = json_response(conn!, 200)

      conn! = get(conn!, Routes.apps_path(conn!, :index))

      [app | _tail] = conn!.assigns.root
      app_service_name = app.service_name

      assert [
               %{
                 "name" => "test",
                 "service_name" => ^app_service_name,
                 "color" => "ffffff",
                 "icon" => 31,
                 "id" => _
               }
             ] = json_response(conn!, 200)
    end
  end

  describe "create" do
    @tag auth_user_with_cgs: :dev
    test "apps controller authenticated", %{conn: conn} do
      conn = create_app_test(conn)
      assert app = json_response(conn, 200)

      user_id = LenraWeb.Auth.current_resource(conn).id

      app_service_name = app["service_name"]

      assert %{
               "color" => "ffffff",
               "icon" => 31,
               "name" => "test",
               "service_name" => ^app_service_name,
               "creator_id" => ^user_id
             } = app
    end

    @tag auth_user_with_cgs: :dev
    test "apps controller authenticated but incorrect params", %{conn: conn} do
      conn =
        post(conn, Routes.apps_path(conn, :create), %{
          "name" => 1234,
          "service_name" => 1234,
          "color" => 1234,
          "icon" => "test"
        })

      assert %{"message" => "name is invalid", "reason" => "invalid_name"} = json_response(conn, 400)
    end
  end

  describe "get user apps" do
    @tag auth_user_with_cgs: :dev
    test "apps controller authenticated", %{conn: conn} do
      conn = create_app_test(conn)
      assert %{} = json_response(conn, 200)

      conn! = get(conn, Routes.apps_path(conn, :get_user_apps))

      assert apps = json_response(conn!, 200)

      user_id = LenraWeb.Auth.current_resource(conn!).id

      app_service_name = Enum.at(apps, 0)["service_name"]

      assert %{
               "color" => "ffffff",
               "icon" => 31,
               "name" => "test",
               "service_name" => ^app_service_name,
               "creator_id" => ^user_id,
               "repository" => "http://repository.com/link.git",
               "repository_branch" => "master"
             } = Enum.at(apps, 0)
    end
  end

  describe "delete" do
    @tag auth_user_with_cgs: :dev
    test "apps controller authenticated", %{conn: conn!} do
      conn! = create_app_test(conn!)

      assert app = json_response(conn!, 200)
      conn! = delete(conn!, Routes.apps_path(conn!, :delete, app["id"]))

      assert %{} == json_response(conn!, 200)

      assert [] == Repo.all(App)
    end

    @tag auth_user_with_cgs: :dev
    test "apps controller authenticated but app does not exist", %{conn: conn!} do
      route = Routes.apps_path(conn!, :delete, "42")

      conn! = delete(conn!, route)

      assert %{"message" => "Not Found.", "reason" => "error_404", "metadata" => %{}} ==
               json_response(conn!, 404)
    end

    @tag auth_user_with_cgs: :user
    test "create app user authenticated but not a dev or admin", %{conn: conn!} do
      conn! = create_app_test(conn!)

      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(conn!, 403)
    end

    @tag auth_user_with_cgs: :dev
    test "create app user authenticated and is a dev", %{conn: conn!} do
      conn! = create_app_test(conn!)

      assert _data = json_response(conn!, 200)
    end

    @tag auth_user_with_cgs: :admin
    test "create app user authenticated and is admin", %{conn: conn!} do
      conn! = create_app_test(conn!)

      assert _data = json_response(conn!, 200)
    end

    @tag auth_users_with_cgs: [:dev, :dev]
    test "delete app not same user", %{users: [conn1!, conn2!]} do
      conn1! = create_app_test(conn1!)

      assert %{"id" => id} = json_response(conn1!, 200)

      conn2! = delete(conn2!, Routes.apps_path(conn2!, :delete, id))

      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(conn2!, 403)

      conn1! = delete(conn1!, Routes.apps_path(conn1!, :delete, id))
      assert %{} = json_response(conn1!, 200)
    end

    @tag auth_users_with_cgs: [:dev, :admin]
    test "delete app not same user but is admin", %{users: [conn1, conn2]} do
      conn1 = create_app_test(conn1)
      assert app = json_response(conn1, 200)

      conn2 = delete(conn2, Routes.apps_path(conn2, :delete, app["id"]))
      assert %{} = json_response(conn2, 200)
    end
  end

  describe "all_apps_user_opened" do
    @tag auth_user_with_cgs: :dev
    test "but never opened apps", %{conn: conn} do
      conn = get(conn, Routes.apps_path(conn, :index))

      LenraWeb.Auth.current_resource(conn).id

      conn! = get(conn, Routes.apps_path(conn, :all_apps_user_opened))
      assert [] = json_response(conn!, 200)
    end
  end

  describe "get_app_by_id" do
    @tag auth_user_with_cgs: :dev
    test "should return app if user is the creator", %{conn: conn} do
      conn = create_app_test(conn)
      assert app = json_response(conn, 200)

      conn! = get(conn, Routes.apps_path(conn, :get_app_by_service_name, app["service_name"]))

      assert %{"color" => "ffffff", "name" => "test", "service_name" => app["service_name"]} ==
               json_response(conn!, 200)
    end

    @tag auth_users_with_cgs: [:dev, :dev]
    test "should return app if user is not the creator", %{users: [conn1!, conn2!]} do
      conn1! = create_app_test(conn1!)
      assert app = json_response(conn1!, 200)

      conn2! = get(conn2!, Routes.apps_path(conn2!, :get_app_by_service_name, app["service_name"]))

      assert %{"color" => "ffffff", "name" => "test", "service_name" => app["service_name"]} ==
               json_response(conn2!, 200)
    end

    @tag auth_user_with_cgs: :dev
    test "should return 404 if app does not exist", %{conn: conn} do
      conn = get(conn, Routes.apps_path(conn, :get_app_by_service_name, Ecto.UUID.generate()))

      assert %{"reason" => "error_404"} = json_response(conn, 404)
    end
  end
end
