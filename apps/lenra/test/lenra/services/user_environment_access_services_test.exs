defmodule Lenra.UserEnvironmentAccessServicesTest do
  @moduledoc """
    Test the user environment access services
  """
  use Lenra.RepoCase, async: true

  alias Lenra.{
    Environment,
    LenraApplication,
    LenraApplicationServices,
    Repo,
    UserEnvironmentAccessServices
  }

  setup do
    {:ok, create_and_return_application()}
  end

  defp create_and_return_application do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    LenraApplicationServices.create(user.id, %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    })

    %{app: Enum.at(Repo.all(LenraApplication), 0), env: Enum.at(Repo.all(Environment), 0)}
  end

  describe "all" do
    test "no user access for environment", %{app: _app, env: env} do
      assert [] == UserEnvironmentAccessServices.all(env.id)
    end

    test "one user access for environment", %{app: app, env: env} do
      UserEnvironmentAccessServices.create(env.id, %{"user_id" => app.creator_id})

      assert 1 ==
               env.id
               |> UserEnvironmentAccessServices.all()
               |> Enum.count()
    end
  end

  describe "create" do
    test "user environment access successfully", %{app: app, env: env} do
      UserEnvironmentAccessServices.create(env.id, %{"user_id" => app.creator_id})

      access =
        env.id
        |> UserEnvironmentAccessServices.all()
        |> Enum.at(0)

      assert access.environment_id == env.id
      assert access.user_id == app.creator_id
    end

    test "user environment access but already exists", %{app: app, env: env} do
      UserEnvironmentAccessServices.create(env.id, %{"user_id" => app.creator_id})

      error = UserEnvironmentAccessServices.create(env.id, %{"user_id" => app.creator_id})

      assert {:error, :inserted_user_access, _failed_value, _changes_so_far} = error
    end

    test "user environment access but invalid params", %{app: app, env: env} do
      error = UserEnvironmentAccessServices.create(env.id + 1, %{"user_id" => app.creator_id + 1})

      assert {:error, :inserted_user_access, _failed_value, _changes_so_far} = error
    end
  end

  describe "delete" do
    test "user environment access successfully", %{app: app, env: env} do
      UserEnvironmentAccessServices.create(env.id, %{"user_id" => app.creator_id})

      env.id
      |> UserEnvironmentAccessServices.all()
      |> Enum.at(0)
      |> UserEnvironmentAccessServices.delete()
      |> Repo.transaction()

      assert [] == UserEnvironmentAccessServices.all(env.id)
    end
  end
end
