defmodule LenraWeb.BuildControllerTest do
  use LenraWeb.ConnCase, async: true

  alias Lenra.GitlabStubHelper

  setup %{conn: conn} do
    GitlabStubHelper.create_gitlab_stub()
    {:ok, conn: conn}
  end

  defp create_app(conn) do
    post(conn, Routes.apps_path(conn, :create), %{
      "name" => "test",
      "color" => "ffffff",
      "icon" => 12
    })
  end

  defp create_build(conn, app_id) do
    post(
      conn,
      Routes.builds_path(
        conn,
        :create,
        app_id
      ),
      %{
        "commit_hash" => "test"
      }
    )
  end

  defp create_app_and_build(conn!) do
    conn! = create_app(conn!)
    assert %{"success" => true, "data" => %{"app" => app}} = json_response(conn!, 200)

    conn! = create_build(conn!, app["id"])
    assert %{"success" => true, "data" => %{"build" => build}} = json_response(conn!, 200)

    %{conn: conn!, app: app, build: build}
  end

  describe "index" do
    test "build controller not authenticated", %{conn: conn} do
      conn = get(conn, Routes.builds_path(conn, :index, 0))

      assert json_response(conn, 401) == %{
               "errors" => [%{"code" => 401, "message" => "You are not authenticated"}],
               "success" => false
             }
    end

    @tag auth_users: [:dev, :user, :dev, :admin]
    test "build controller authenticated", %{users: [creator!, user, other_dev, admin]} do
      %{conn: creator!, app: app} = create_app_and_build(creator!)

      get_build_path = Routes.builds_path(creator!, :index, app["id"])
      creator! = get(creator!, get_build_path)
      user = get(user, get_build_path)
      other_dev = get(other_dev, get_build_path)
      admin = get(admin, get_build_path)

      assert %{
               "data" => %{
                 "builds" => [
                   %{
                     "build_number" => 1,
                     "commit_hash" => "test",
                     "status" => "pending",
                     "application_id" => _,
                     "creator_id" => _,
                     "id" => _
                   }
                 ]
               },
               "success" => true
             } = json_response(creator!, 200)

      assert %{
               "data" => %{
                 "builds" => [
                   %{
                     "build_number" => 1,
                     "commit_hash" => "test",
                     "status" => "pending",
                     "application_id" => _,
                     "creator_id" => _,
                     "id" => _
                   }
                 ]
               },
               "success" => true
             } = json_response(admin, 200)

      assert %{"success" => false} = json_response(user, 403)
      assert %{"success" => false} = json_response(other_dev, 403)
    end
  end

  describe "create" do
    @tag auth_users: [:dev, :user, :dev, :admin]
    test "build controller authenticated", %{users: [creator!, user, other_dev, admin]} do
      creator! = create_app(creator!)
      assert %{"success" => true, "data" => %{"app" => app}} = json_response(creator!, 200)

      creator! = create_build(creator!, app["id"])
      admin = create_build(admin, app["id"])
      user = create_build(user, app["id"])
      other_dev = create_build(other_dev, app["id"])

      assert %{"success" => true, "data" => %{"build" => _}} = json_response(creator!, 200)
      assert %{"success" => true, "data" => %{"build" => _}} = json_response(admin, 200)

      assert %{"success" => false, "errors" => [%{"code" => 403, "message" => "Forbidden"}]} = json_response(user, 403)

      assert %{"success" => false, "errors" => [%{"code" => 403, "message" => "Forbidden"}]} =
               json_response(other_dev, 403)
    end

    @tag auth_user: :dev
    test "build controller authenticated check build_number incremented", %{conn: conn!} do
      %{conn: conn!, app: app, build: build} = create_app_and_build(conn!)

      conn! =
        post(
          conn!,
          Routes.builds_path(
            conn!,
            :create,
            app["id"]
          ),
          %{
            "commit_hash" => "test2"
          }
        )

      assert %{"build_number" => 1} = build

      assert %{"success" => true, "data" => %{"build" => %{"build_number" => 2}}} = json_response(conn!, 200)
    end

    @tag auth_user: :dev
    test "build controller authenticated but invalid params", %{conn: conn!} do
      conn! = create_app(conn!)

      assert %{"success" => true, "data" => %{"app" => app}} = json_response(conn!, 200)

      conn! =
        post(
          conn!,
          Routes.builds_path(
            conn!,
            :create,
            app["id"]
          ),
          %{
            "commit_hash" => 1234
          }
        )

      assert %{
               "success" => false,
               "errors" => [%{"code" => 0, "message" => "commit_hash is invalid"}]
             } = json_response(conn!, 400)

      assert %{
               "errors" => [
                 %{"code" => 0, "message" => "commit_hash is invalid"}
               ],
               "success" => false
             } == json_response(conn!, 400)
    end
  end
end
