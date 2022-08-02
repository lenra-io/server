defmodule LenraWeb.RunnerControllerTest do
  use LenraWeb.ConnCase, async: true

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

      assert %{"data" => app} = json_response(conn!, 200)

      conn! = post(conn!, Routes.builds_path(conn!, :create, app["id"]))
      assert %{"data" => build} = json_response(conn!, 200)

      {:ok, %{conn: conn!, app: app, build: build}}
    end

    @tag auth_user_with_cgu: :dev
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

    @tag auth_user_with_cgu: :dev
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

    @tag auth_user_with_cgu: :dev
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
               "message" => "Server cannot understand or process the request due to a client-side error.",
               "reason" => "bad_request"
             } = json_response(conn, 400)
    end
  end
end
