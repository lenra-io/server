defmodule Lenra.Apps.DeploymentTest do
  @moduledoc """
    Test the deployment services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.{
    FaasStub,
    GitlabStubHelper,
    Repo
  }

  alias Lenra.Apps
  alias Lenra.Apps.{App, Build, Deployment, Environment}

  setup do
    GitlabStubHelper.create_gitlab_stub()
    {:ok, app: create_and_return_application()}
  end

  defp create_and_return_application do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    Apps.create_app(user.id, %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    })

    app = Enum.at(Repo.all(App), 0)

    Apps.create_build_and_trigger_pipeline(app.creator_id, app.id, %{
      commit_hash: "abcdef"
    })

    app
  end

  describe "create" do
    test "deployment successfully", %{app: app} do
      FaasStub.create_faas_stub()
      |> FaasStub.expect_deploy_app_once(%{"ok" => "200"})

      env = Enum.at(Repo.all(Environment), 0)
      build = Enum.at(Repo.all(Build), 0)

      Apps.create_deployment(env.id, build.id, app.creator_id)

      assert nil != Enum.at(Repo.all(Deployment), 0)
      assert nil != Repo.get_by(Deployment, environment_id: env.id, build_id: build.id)
    end

    test "deployment but wrong environment", %{app: app} do
      {:ok, %{inserted_env: wrong_env}} =
        Apps.create_app(app.creator_id, %{
          name: "wrong_app",
          color: "FFFFFF",
          icon: "60189"
        })

      build = Enum.at(Repo.all(Build), 0)
      error = Apps.create_deployment(wrong_env.id, build.id, app.creator_id)

      assert {:error, :inserted_deployment, _failed_value, _changes_so_far} = error
      assert nil == Enum.at(Repo.all(Deployment), 0)
    end
  end
end
