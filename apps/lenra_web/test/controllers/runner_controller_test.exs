defmodule LenraWeb.RunnerControllerTest do
  use LenraWeb.ConnCase, async: true

  alias Lenra.Apps.App
  alias Lenra.{FaasStub, GitlabStubHelper}

  setup %{conn: conn} do
    GitlabStubHelper.create_gitlab_stub()
    {:ok, conn: conn}
  end

  describe "update build status" do
    setup %{conn: conn!} do
      conn! =
        post(conn!, Routes.apps_path(conn!, :create), %{
          "name" => "test",
          "color" => "ffffff",
          "icon" => 12,
          "repository" => "https://gitlab.com/myname/test.git"
        })

      assert app = json_response(conn!, 200)

      preloaded_app = Lenra.Repo.preload(Lenra.Repo.get(App, app["id"]), :main_env)

      conn! = post(conn!, Routes.builds_path(conn!, :create, app["id"]))
      assert build = json_response(conn!, 200)

      post(conn!, Routes.deployments_path(conn!, :create), %{
        environment_id: preloaded_app.main_env.environment_id,
        build_id: build["id"],
        application_id: app["id"]
      })

      assert json_response(conn!, 200)

      {:ok, %{conn: conn!, app: app, build: build}}
    end

    @tag auth_user_with_cgs: :dev
    test "set state failure", %{conn: conn, build: build} do
      conn =
        put(
          conn,
          Routes.runner_path(conn, :update_build, build["id"], %{"secret" => "test_secret"}),
          %{
            "status" => "failure"
          }
        )

      assert %{} = json_response(conn, 200)
    end

    @tag auth_user_with_cgs: :dev
    test "set state success", %{conn: conn, build: build} do
      FaasStub.create_faas_stub()
      |> FaasStub.expect_deploy_app_once(%{"ok" => "200"})

      conn =
        put(
          conn,
          Routes.runner_path(conn, :update_build, build["id"], %{"secret" => "test_secret"}),
          %{
            "status" => "success"
          }
        )

      assert %{} = json_response(conn, 200)
    end

    @tag auth_user_with_cgs: :dev
    test "set state non working", %{conn: conn, build: build} do
      conn =
        put(
          conn,
          Routes.runner_path(conn, :update_build, build["id"], %{"secret" => "test_secret"}),
          %{
            "status" => "error"
          }
        )

      assert %{
               "message" => "Internal server error.",
               "reason" => "error_500"
             } = json_response(conn, 500)
    end
  end
end
