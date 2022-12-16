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
    assert app = json_response(conn!, 200)

    conn! = create_build(conn!, app["id"])
    assert build = json_response(conn!, 200)

    %{conn: conn!, app: app, build: build}
  end

  describe "index" do
    test "build controller not authenticated", %{conn: conn} do
      conn = get(conn, Routes.builds_path(conn, :index, 0))

      assert json_response(conn, 401) == %{
               "message" => "You are not authenticated",
               "reason" => "unauthenticated"
             }
    end

    @tag auth_users_with_cgu: [:user, :user, :admin]
    test "build controller authenticated", %{users: [creator!, other_user, admin]} do
      %{conn: creator!, app: app} = create_app_and_build(creator!)

      get_build_path = Routes.builds_path(creator!, :index, app["id"])
      creator! = get(creator!, get_build_path)
      other_user = get(other_user, get_build_path)
      admin = get(admin, get_build_path)

      assert [
               %{
                 "build_number" => 1,
                 "commit_hash" => "test",
                 "status" => "pending",
                 "application_id" => _,
                 "creator_id" => _,
                 "id" => _
               }
             ] = json_response(creator!, 200)

      assert [
               %{
                 "build_number" => 1,
                 "commit_hash" => "test",
                 "status" => "pending",
                 "application_id" => _,
                 "creator_id" => _,
                 "id" => _
               }
             ] = json_response(admin, 200)

      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(other_user, 403)
    end
  end

  describe "create" do
    @tag auth_users_with_cgu: [:user, :user, :admin]
    test "build controller authenticated", %{users: [creator!, other_user, admin]} do
      creator! = create_app(creator!)
      assert app = json_response(creator!, 200)

      creator! = create_build(creator!, app["id"])
      admin = create_build(admin, app["id"])
      other_user = create_build(other_user, app["id"])

      assert %{} = json_response(creator!, 200)
      assert %{} = json_response(admin, 200)

      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(other_user, 403)
    end

    @tag auth_user_with_cgu: :user
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

      assert %{"build_number" => 2} = json_response(conn!, 200)
    end

    @tag auth_user_with_cgu: :user
    test "build controller authenticated but invalid params", %{conn: conn!} do
      conn! = create_app(conn!)

      assert app = json_response(conn!, 200)

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
               "message" => "commit_hash is invalid",
               "reason" => "invalid_commit_hash"
             } = json_response(conn!, 400)

      assert %{
               "message" => "commit_hash is invalid",
               "reason" => "invalid_commit_hash"
             } == json_response(conn!, 400)
    end
  end
end
