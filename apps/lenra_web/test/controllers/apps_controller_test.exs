defmodule LenraWeb.AppsControllerTest do
  use LenraWeb.ConnCase, async: true

  alias Lenra.{LenraApplication, Repo}

  setup %{conn: conn} do
    {:ok, conn: conn}
  end

  defp create_app_test(conn) do
    post(
      conn,
      Routes.apps_path(conn, :create, %{
        "name" => "test",
        "color" => "ffffff",
        "icon" => 31
      })
    )
  end

  describe "index" do
    test "apps controller not authenticated", %{conn: conn} do
      conn = get(conn, Routes.apps_path(conn, :index))

      assert json_response(conn, 401) == %{
               "errors" => [%{"code" => 401, "message" => "You are not authenticated"}],
               "success" => false
             }
    end

    @tag auth_user: :dev
    test "apps controller authenticated", %{conn: conn!} do
      conn! = create_app_test(conn!)
      assert %{"success" => true} = json_response(conn!, 200)

      conn! = get(conn!, Routes.apps_path(conn!, :index))

      [app | _tail] = conn!.assigns.data.apps
      app_service_name = app.service_name

      assert %{
               "data" => %{
                 "apps" => [
                   %{
                     "name" => "test",
                     "service_name" => ^app_service_name,
                     "color" => "ffffff",
                     "icon" => 31,
                     "id" => _
                   }
                 ]
               },
               "success" => true
             } = json_response(conn!, 200)
    end
  end

  describe "create" do
    @tag auth_user: :dev
    test "apps controller authenticated", %{conn: conn} do
      conn = create_app_test(conn)
      assert %{"success" => true, "data" => %{"app" => app}} = json_response(conn, 200)

      user_id = Guardian.Plug.current_resource(conn).id

      app_service_name = app["service_name"]

      assert %{
               "color" => "ffffff",
               "icon" => 31,
               "name" => "test",
               "service_name" => ^app_service_name,
               "creator_id" => ^user_id
             } = app
    end

    @tag auth_user: :dev
    test "apps controller authenticated but incorrect params", %{conn: conn} do
      conn =
        post(conn, Routes.apps_path(conn, :create), %{
          "name" => 1234,
          "service_name" => 1234,
          "color" => 1234,
          "icon" => "test"
        })

      assert %{"errors" => _} = json_response(conn, 400)
    end
  end

  describe "delete" do
    @tag auth_user: :dev
    test "apps controller authenticated", %{conn: conn!} do
      conn! = create_app_test(conn!)

      assert %{"success" => true, "data" => %{"app" => app}} = json_response(conn!, 200)
      conn! = delete(conn!, Routes.apps_path(conn!, :delete, app["id"]))

      assert %{"success" => true} == json_response(conn!, 200)

      assert [] == Repo.all(LenraApplication)
    end

    @tag auth_user: :dev
    test "apps controller authenticated but app does not exist", %{conn: conn!} do
      route = Routes.apps_path(conn!, :delete, "42")

      conn! = delete(conn!, route)

      assert %{"errors" => [%{"code" => 404, "message" => "Not Found."}], "success" => false} ==
               json_response(conn!, 404)
    end

    @tag auth_user: :user
    test "create app user authenticated but not a dev or admin", %{conn: conn!} do
      conn! = create_app_test(conn!)

      assert %{"success" => false, "errors" => [%{"code" => 403, "message" => "Forbidden"}]} = json_response(conn!, 403)
    end

    @tag auth_user: :dev
    test "create app user authenticated and is a dev", %{conn: conn!} do
      conn! = create_app_test(conn!)

      assert %{"success" => true} = json_response(conn!, 200)
    end

    @tag auth_user: :admin
    test "create app user authenticated and is admin", %{conn: conn!} do
      conn! = create_app_test(conn!)

      assert %{"success" => true} = json_response(conn!, 200)
    end

    @tag auth_users: [:dev, :dev]
    test "delete app not same user", %{users: [conn1!, conn2!]} do
      conn1! = create_app_test(conn1!)

      assert %{"success" => true, "data" => %{"app" => %{"id" => id}}} = json_response(conn1!, 200)

      conn2! = delete(conn2!, Routes.apps_path(conn2!, :delete, id))

      assert %{"success" => false, "errors" => [%{"code" => 403, "message" => "Forbidden"}]} =
               json_response(conn2!, 403)

      conn1! = delete(conn1!, Routes.apps_path(conn1!, :delete, id))
      assert %{"success" => true} = json_response(conn1!, 200)
    end

    @tag auth_users: [:dev, :admin]
    test "delete app not same user but is admin", %{users: [conn1, conn2]} do
      conn1 = create_app_test(conn1)
      assert %{"success" => true, "data" => %{"app" => app}} = json_response(conn1, 200)

      conn2 = delete(conn2, Routes.apps_path(conn2, :delete, app["id"]))
      assert %{"success" => true} = json_response(conn2, 200)
    end
  end
end
