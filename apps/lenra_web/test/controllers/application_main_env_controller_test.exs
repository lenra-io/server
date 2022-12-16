defmodule LenraWeb.ApplicationMainEnvControllerTest do
  use LenraWeb.ConnCase, async: true

  alias Lenra.GitlabStubHelper

  setup %{conn: conn} do
    GitlabStubHelper.create_gitlab_stub()
    {:ok, conn: conn}
  end

  def create_app(conn) do
    conn =
      post(conn, Routes.apps_path(conn, :create), %{
        "name" => "test",
        "color" => "ffffff",
        "icon" => 12
      })

    app = json_response(conn, 200)

    %{conn: conn, app: app}
  end

  describe "index" do
    test "application main env controller not authenticated", %{conn: conn} do
      conn = get(conn, Routes.application_main_env_path(conn, :index, 0))

      assert json_response(conn, 401) == %{
               "message" => "You are not authenticated",
               "reason" => "unauthenticated"
             }
    end

    @tag auth_users_with_cgu: [:user, :user, :admin]
    test "application main env controller authenticated", %{users: [creator!, other_user, admin]} do
      %{conn: creator!, app: app} = create_app(creator!)

      get_application_main_env_path = Routes.application_main_env_path(creator!, :index, app["id"])
      creator! = get(creator!, get_application_main_env_path)
      other_user = get(other_user, get_application_main_env_path)
      admin = get(admin, get_application_main_env_path)

      assert %{
               "application_id" => _,
               "name" => "live",
               "creator_id" => _,
               "deployed_build_id" => _,
               "id" => _,
               "is_ephemeral" => false,
               "is_public" => false
             } = json_response(creator!, 200)

      assert %{
               "application_id" => _,
               "name" => "live",
               "creator_id" => _,
               "deployed_build_id" => _,
               "id" => _,
               "is_ephemeral" => false,
               "is_public" => false
             } = json_response(admin, 200)

      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(other_user, 403)
    end
  end
end
