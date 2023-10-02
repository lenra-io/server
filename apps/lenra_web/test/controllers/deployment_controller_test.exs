defmodule LenraWeb.DeploymentControllerTest do
  use LenraWeb.ConnCase, async: true

  alias Lenra.{
    GitlabStubHelper,
    Repo
  }

  alias Lenra.Apps.{App, Build, Deployment, Environment}
  alias Lenra.Repo

  setup %{conn: conn} do
    GitlabStubHelper.create_gitlab_stub()
    {:ok, conn: conn}
  end

  describe "create" do
    @tag auth_user_with_cgs: :dev
    test "deployment controller authenticated", %{conn: conn!} do
      conn! =
        post(conn!, Routes.apps_path(conn!, :create), %{
          "name" => "test",
          "color" => "ffffff",
          "icon" => 12
        })

      {:ok, app} = Enum.fetch(Repo.all(App), 0)

      conn! =
        post(
          conn!,
          Routes.builds_path(
            conn!,
            :create,
            app.id
          ),
          %{
            "commit_hash" => "test"
          }
        )

      env = Enum.at(Repo.all(Environment), 0)
      build = Enum.at(Repo.all(Build), 0)

      post(conn!, Routes.deployments_path(conn!, :create), %{
        environment_id: env.id,
        build_id: build.id,
        application_id: app.id
      })

      assert [] != Repo.all(Deployment)
    end

    @tag auth_user_with_cgs: :dev
    test "deployment controller but wrong environment", %{conn: conn!} do
      conn! =
        post(conn!, Routes.apps_path(conn!, :create), %{
          "name" => "test",
          "color" => "ffffff",
          "icon" => 12
        })

      assert app = json_response(conn!, 200)

      conn! =
        post(conn!, Routes.apps_path(conn!, :create), %{
          "name" => "testtest",
          "color" => "ffffff",
          "icon" => 12
        })

      assert wrong_app = json_response(conn!, 200)

      conn! =
        post(
          conn!,
          Routes.builds_path(
            conn!,
            :create,
            app["id"]
          ),
          %{
            "commit_hash" => "test"
          }
        )

      assert build = json_response(conn!, 200)

      {:ok, wrong_env} = Repo.fetch_by(Environment, application_id: wrong_app["id"])

      conn! =
        post(conn!, Routes.deployments_path(conn!, :create), %{
          environment_id: wrong_env.id,
          build_id: build["id"],
          application_id: app["id"]
        })

      assert %{
               "message" => "environment_id does not exist",
               "reason" => "invalid_environment_id"
             } ==
               json_response(conn!, 400)
    end
  end
end
