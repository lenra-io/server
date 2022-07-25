defmodule Lenra.AppsTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{Repo, UserEnvironmentAccessServices}

  alias Lenra.Apps
  alias Lenra.Repo

  setup do
    {:ok, create_applications_and_return_user()}
  end

  defp create_applications_and_return_user do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    Apps.create_app(user.id, %{
      name: "private-app",
      color: "FFFFFF",
      icon: "60189",
      repository: "http://repository.com/link.git",
      repository_branch: "master"
    })

    {:ok, %{application_main_env: main_env}} =
      Apps.create_app(user.id, %{
        name: "public-app",
        color: "FFFFFF",
        icon: "60189",
        repository: "http://repository.com/link.git",
        repository_branch: "beta"
      })

    env = Repo.preload(main_env, :environment).environment

    Apps.update_env(env, %{is_public: true})

    {:ok, %{inserted_user: random_user}} = UserTestHelper.register_user_nb(1, :user)

    %{user: user, random_user: random_user}
  end

  describe "all_apps" do
    test "creator of both apps can see both", %{user: user, random_user: _random_user} do
      apps = Apps.all_apps(user.id)
      assert length(apps) == 2
    end

    test "random user can only see public-app", %{user: _user, random_user: random_user} do
      apps = Apps.all_apps(random_user.id)
      assert length(apps) == 1

      assert [%{name: "public-app"}] = apps
    end

    test "random user can see both apps if invited on the private one", %{user: _user, random_user: random_user} do
      {:ok, app} = Apps.fetch_app_by(name: "private-app")
      app_preload = Repo.preload(app, main_env: :environment)
      UserEnvironmentAccessServices.create(app_preload.main_env.environment.id, %{"user_id" => random_user.id})

      apps = Apps.all_apps(random_user.id)
      assert length(apps) == 2
    end
  end

  describe "all_apps_for_user" do
    test "creator of both apps can see both", %{user: user, random_user: _random_user} do
      apps = Apps.all_apps_for_user(user.id)
      assert length(apps) == 2
    end

    test "random user can only see his apps if he has any", %{user: _user, random_user: random_user} do
      apps = Apps.all_apps_for_user(random_user.id)
      assert apps == []
    end
  end

  describe "update" do
    test "application successfully", %{user: _user, random_user: _random_user} do
      {:ok, app} = Apps.fetch_app_by(name: "public-app")

      Apps.update_app(app, %{
        repository: "new_repo"
      })

      {:ok, updated_app} = Apps.fetch_app_by(name: "public-app")

      assert app.repository != updated_app.repository
      assert app.repository == "http://repository.com/link.git"
      assert updated_app.repository == "new_repo"
    end
  end
end
