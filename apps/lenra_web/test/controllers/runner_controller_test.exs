defmodule LenraWeb.RunnerControllerTest do
  use LenraWeb.ConnCase, async: true

  alias Lenra.GitlabStubHelper
  alias Lenra.FaasStub, as: AppStub

  setup %{conn: conn} do
    GitlabStubHelper.create_gitlab_stub()
    {:ok, conn: conn}
  end

  describe "update build status" do
    setup %{conn: conn} do
      conn =
        post(conn, Routes.apps_path(conn, :create), %{
          "name" => "test",
          "service_name" => Ecto.UUID.generate(),
          "color" => "ffffff",
          "icon" => 12,
          "repository" => "https://gitlab.com/myname/test.git"
        })

      assert %{"success" => true, "data" => %{"app" => app}} = json_response(conn, 200)

      conn = post(conn, Routes.builds_path(conn, :create, app["id"]))
      assert %{"success" => true, "data" => %{"build" => build}} = json_response(conn, 200)

      {:ok, %{conn: conn, app: app, build: build}}
    end

    @tag auth_user: :dev
    test "set state failure", %{conn: conn, build: build} do
      conn =
        put(conn, Routes.runner_path(conn, :update_build, build["id"], %{"secret" => "test_secret"}), %{
          "status" => "failure"
        })

      assert %{"success" => true} = json_response(conn, 200)
    end

    @tag auth_user: :dev
    test "set state success", %{conn: conn, build: build} do
      AppStub.create_faas_stub()
      |> AppStub.expect_deploy_app_once(%{"ok" => "200"})

      conn =
        put(conn, Routes.runner_path(conn, :update_build, build["id"], %{"secret" => "test_secret"}), %{
          "status" => "success"
        })

      assert %{"success" => true} = json_response(conn, 200)
    end

    @tag auth_user: :dev
    test "set state non working", %{conn: conn, build: build} do
      conn =
        put(conn, Routes.runner_path(conn, :update_build, build["id"], %{"secret" => "test_secret"}), %{
          "status" => "error"
        })

      assert %{"success" => false} = json_response(conn, 400)
    end
  end
end
