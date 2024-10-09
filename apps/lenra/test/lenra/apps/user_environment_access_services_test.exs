defmodule Lenra.UserEnvironmentAccessServicesTest do
  @moduledoc """
    Test the user environment access services
  """
  use Lenra.RepoCase, async: false
  use Bamboo.Test, shared: true

  alias Lenra.{
    EmailService,
    Repo
  }

  alias Lenra.Apps
  alias Lenra.Apps.{App, Environment}

  setup do
    {:ok, create_and_return_application()}
  end

  defp create_and_return_application do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    Apps.create_app(user.id, %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    })

    %{app: Enum.at(Repo.all(App), 0), env: Enum.at(Repo.all(Environment), 0), user: user}
  end

  describe "all" do
    test "no user access role for environment", %{app: _app, env: env, user: _user} do
      assert [] == Apps.all_user_env_access(env.id)
    end

    test "one user access for environment", %{app: _app, env: env, user: user} do
      Apps.create_user_env_access(env.id, %{"email" => user.email}, nil)

      assert 1 ==
               env.id
               |> Apps.all_user_env_access()
               |> Enum.count()
    end
  end

  describe "create" do
    test "user environment access successfully", %{app: _app, env: env, user: user} do
      Apps.create_user_env_access(env.id, %{"email" => user.email}, nil)

      access =
        env.id
        |> Apps.all_user_env_access()
        |> Enum.at(0)

      assert access.environment_id == env.id
      assert access.email == user.email
    end

    test "user access role but already exists", %{app: _app, env: env, user: user} do
      Apps.create_user_access_role(env.id, %{"email" => user.email}, nil)

      error = Apps.create_user_env_access(env.id, %{"email" => user.email}, nil)

      assert {:error, :inserted_user_access, _failed_value, _changes_so_far} = error
    end

    test "user environment access but invalid params", %{app: _app, env: env, user: _user} do
      assert {:error, :inserted_user_access, _failed_value, _changes_so_far} =
               Apps.create_user_env_access(env.id + 1, %{"email" => ""}, nil)
    end
  end

  describe "create user env access from email" do
    test "successfully", %{app: _app, env: env, user: user} do
      Apps.create_user_env_access(env.id, %{"email" => user.email}, nil)

      access =
        env.id
        |> Apps.all_user_env_access()
        |> Enum.at(0)

      assert access.environment_id == env.id
      assert access.email == user.email
    end

    test "unknown email", %{app: _app, env: env, user: _user} do
      assert {:ok, %{inserted_user_access: user_access}} =
               Apps.create_user_env_access(env.id, %{"email" => "test@lenra.io"}, nil)

      assert user_access.environment_id == env.id
      assert user_access.user_id == nil

      {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe(%{"email" => "test@lenra.io"})

      Apps.accept_invitation(user_access.id, user)

      access = Repo.get_by(Apps.UserEnvironmentAccess, id: user_access.id)

      assert access.environment_id == env.id
      assert access.user_id == user.id
    end
  end

  describe "delete" do
    test "user environment access successfully", %{app: _app, env: env, user: user} do
      {:ok, %{inserted_user_access: user_access}} = Apps.create_user_env_access(env.id, %{"email" => user.email}, nil)

      Apps.UserEnvironmentAccess
      |> Repo.get_by(id: user_access.id)
      |> Apps.delete_user_env_access()
      |> Repo.transaction()

      assert [] == Apps.all_user_env_access(env.id)
    end
  end
end
