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

    %{"data" => app} = json_response(conn, 200)

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

    @tag auth_users: [:dev, :user, :dev, :admin]
    test "application main env controller authenticated", %{users: [creator!, user, other_dev, admin]} do
      %{conn: creator!, app: app} = create_app(creator!)

      get_application_main_env_path = Routes.application_main_env_path(creator!, :index, app["id"])
      creator! = get(creator!, get_application_main_env_path)
      user = get(user, get_application_main_env_path)
      other_dev = get(other_dev, get_application_main_env_path)
      admin = get(admin, get_application_main_env_path)

      assert %{
               "data" => %{
                 "application_id" => _,
                 "name" => "live",
                 "creator_id" => _,
                 "deployed_build_id" => _,
                 "id" => _,
                 "is_ephemeral" => false,
                 "is_public" => false
               }
             } = json_response(creator!, 200)

      assert %{
               "data" => %{
                 "application_id" => _,
                 "name" => "live",
                 "creator_id" => _,
                 "deployed_build_id" => _,
                 "id" => _,
                 "is_ephemeral" => false,
                 "is_public" => false
               }
             } = json_response(admin, 200)

      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(user, 403)
      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(other_dev, 403)
    end
  end
end
