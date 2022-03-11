defmodule LenraWeb.LenraApplicationServicesTest do
  use Lenra.RepoCase, async: true

  alias Lenra.{EnvironmentServices, LenraApplicationServices, Repo, UserEnvironmentAccessServices}

  setup do
    create_applications_and_return_user()
    %{hash: "Test", link: "test", version: "1.0.0"} |> Lenra.Cgu.new() |> Repo.insert()
    :ok
  end

  defp create_applications_and_return_user do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    LenraApplicationServices.create(user.id, %{
      name: "private-app",
      color: "FFFFFF",
      icon: "60189"
    })

    {:ok, %{application_main_env: main_env}} =
      LenraApplicationServices.create(user.id, %{
        name: "public-app",
        color: "FFFFFF",
        icon: "60189"
      })

    env = Repo.preload(main_env, :environment).environment

    EnvironmentServices.update(env, %{is_public: true})

    {:ok, %{inserted_user: random_user}} = UserTestHelper.register_user_nb(1, :user)

    %{user: user, random_user: random_user}
  end

  describe "all" do
    test "creator of both apps can see both", %{user: user, random_user: _random_user} do
      apps = LenraApplicationServices.all(user.id)
      assert length(apps) == 2
    end

    test "random user can only see public-app", %{user: _user, random_user: random_user} do
      apps = LenraApplicationServices.all(random_user.id)
      assert length(apps) == 1

      assert [%{name: "public-app"}] = apps
    end

    test "random user can see both apps if invited on the private one", %{user: _user, random_user: random_user} do
      {:ok, app} = LenraApplicationServices.fetch_by(name: "private-app")
      app_preload = Repo.preload(app, main_env: :environment)
      UserEnvironmentAccessServices.create(app_preload.main_env.environment.id, %{"user_id" => random_user.id})

      apps = LenraApplicationServices.all(random_user.id)
      assert length(apps) == 2
    end
  end

  describe "all_for_user" do
    test "creator of both apps can see both", %{user: user, random_user: _random_user} do
      apps = LenraApplicationServices.all_for_user(user.id)
      assert length(apps) == 2
    end

    test "random user can only see his apps if he has any", %{user: _user, random_user: random_user} do
      apps = LenraApplicationServices.all_for_user(random_user.id)
      assert apps == []
    end
  end
end
