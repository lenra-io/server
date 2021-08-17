defmodule LenraServers.DeploymentServicesTest do
  @moduledoc """
    Test the deployment services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.FaasStub, as: AppStub

  alias Lenra.{
    Repo,
    Build,
    Environment,
    Deployment,
    LenraApplication,
    BuildServices,
    LenraApplicationServices,
    DeploymentServices,
    GitlabStubHelper
  }

  setup do
    GitlabStubHelper.create_gitlab_stub()
    {:ok, app: create_and_return_application()}
  end

  defp create_and_return_application do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    LenraApplicationServices.create(user.id, %{
      name: "mine-sweeper",
      service_name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    })

    app = Enum.at(Repo.all(LenraApplication), 0)

    BuildServices.create_and_trigger_pipeline(app.creator_id, app.id, %{
      commit_hash: "abcdef"
    })

    app
  end

  describe "get" do
    test "not existing deployment", %{app: _app} do
      assert nil == DeploymentServices.get(0)
    end

    test "existing deployment", %{app: app} do
      AppStub.create_faas_stub()
      |> AppStub.expect_deploy_app_once(%{"ok" => "200"})

      env = Enum.at(Repo.all(Environment), 0)
      build = Enum.at(Repo.all(Build), 0)

      DeploymentServices.create(env.id, build.id, app.creator_id)

      deployment = Enum.at(Repo.all(Deployment), 0)

      assert deployment == DeploymentServices.get(deployment.id)
    end
  end

  describe "get by" do
    test "env_id and build_id", %{app: app} do
      AppStub.create_faas_stub()
      |> AppStub.expect_deploy_app_once(%{"ok" => "200"})

      env = Enum.at(Repo.all(Environment), 0)
      build = Enum.at(Repo.all(Build), 0)

      DeploymentServices.create(env.id, build.id, app.creator_id)

      deployment = Enum.at(Repo.all(Deployment), 0)

      assert deployment == DeploymentServices.get_by(environment_id: env.id, build_id: build.id)
    end
  end

  describe "create" do
    test "deployment successfully", %{app: app} do
      AppStub.create_faas_stub()
      |> AppStub.expect_deploy_app_once(%{"ok" => "200"})

      env = Enum.at(Repo.all(Environment), 0)
      build = Enum.at(Repo.all(Build), 0)

      DeploymentServices.create(env.id, build.id, app.creator_id)

      assert nil != Enum.at(Repo.all(Deployment), 0)
      assert nil != DeploymentServices.get_by(environment_id: env.id, build_id: build.id)
    end

    test "deployment but wrong environment", %{app: app} do
      {:ok, %{inserted_main_env: wrong_env}} =
        LenraApplicationServices.create(app.creator_id, %{
          name: "wrong_app",
          service_name: "wrong_app",
          color: "FFFFFF",
          icon: "60189"
        })

      build = Enum.at(Repo.all(Build), 0)
      error = DeploymentServices.create(wrong_env.id, build.id, app.creator_id)

      assert {:error, :inserted_deployment, _, _} = error
      assert nil == Enum.at(Repo.all(Deployment), 0)
    end
  end

  describe "delete" do
    test "deployment successfully", %{app: app} do
      AppStub.create_faas_stub()
      |> AppStub.expect_deploy_app_once(%{"ok" => "200"})

      env = Enum.at(Repo.all(Environment), 0)
      build = Enum.at(Repo.all(Build), 0)

      DeploymentServices.create(env.id, build.id, app.creator_id)

      deployment = Enum.at(Repo.all(Deployment), 0)

      assert nil != deployment

      DeploymentServices.delete(deployment)
      |> Repo.transaction()

      assert nil == Enum.at(Repo.all(Deployment), 0)
    end
  end
end
