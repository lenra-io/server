defmodule LenraWeb.ApplicationMainEnvControllerTest do
  use LenraWeb.ConnCase, async: true

  alias Lenra.GitlabStubHelper

  setup %{conn: conn} do
    GitlabStubHelper.create_gitlab_stub()
    {:ok, conn: conn}
  end

  describe "index" do
    test "application main env controller not authenticated", %{conn: conn} do
      conn = get(conn, Routes.application_main_env_path(conn, :index, 0))

      assert json_response(conn, 401) == %{
               "message" => "No Bearer token found in Authorization header",
               "reason" => "token_not_found",
               "metadata" => %{}
             }
    end

    @tag auth_users_with_cgs: [:dev, :user, :dev, :admin]
    test "application main env controller authenticated", %{users: [creator!, user, other_dev, admin]} do
      %{conn: creator!, app: app} = create_app(creator!)

      get_application_main_env_path = Routes.application_main_env_path(creator!, :index, app["id"])
      creator! = get(creator!, get_application_main_env_path)
      user = get(user, get_application_main_env_path)
      other_dev = get(other_dev, get_application_main_env_path)
      admin = get(admin, get_application_main_env_path)

      assert %{
               "application_id" => _,
               "name" => "live",
               "creator_id" => _,
               "deployment_id" => _,
               "id" => _,
               "is_ephemeral" => false,
               "is_public" => false
             } = json_response(creator!, 200)

      assert %{
               "application_id" => _,
               "name" => "live",
               "creator_id" => _,
               "deployment_id" => _,
               "id" => _,
               "is_ephemeral" => false,
               "is_public" => false
             } = json_response(admin, 200)

      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(user, 403)
      assert %{"message" => "Forbidden", "reason" => "forbidden"} = json_response(other_dev, 403)
    end
  end
end
