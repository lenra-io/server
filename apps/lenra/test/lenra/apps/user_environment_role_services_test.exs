defmodule Lenra.UserEnvironmentRoleServicesTest do
  @moduledoc """
    Test the user environment access services
  """
  use Lenra.RepoCase, async: false
  use Bamboo.Test, shared: true

  alias Lenra.Apps
  alias Lenra.Apps.{App, Environment}
  alias Lenra.Repo

  @email "test@lenra.io"

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
    test "no user access for environment", %{app: _app, env: env, user: _user} do
      assert [] == Apps.all_user_env_access_and_roles(env.id)
    end

    test "no user role for environment", %{app: _app, env: env, user: _user} do
      Apps.create_user_env_access(env.id, %{"email" => @email}, nil)

      access_list = Apps.all_user_env_access_and_roles(env.id)

      assert 1 == Enum.count(access_list)

      user_access = Enum.at(access_list, 0)

      assert [] == user_access.roles
    end

    test "one user role for environment", %{app: _app, env: env, user: user} do
      {:ok, %{inserted_user_access: created_user_access}} =
        Apps.create_user_env_access(env.id, %{"email" => @email}, nil)

      {:ok, _} = Apps.create_user_env_role(created_user_access.id, user.id, "admin")

      access_list = Apps.all_user_env_access_and_roles(env.id)

      assert 1 == Enum.count(access_list)
      user_access = Enum.at(access_list, 0)

      [%{role: role}] = user_access.roles
      assert role == "admin"
    end
  end

  describe "create" do
    test "user environment role successfully", %{app: _app, env: env, user: user} do
      {:ok, %{inserted_user_access: user_access}} = Apps.create_user_env_access(env.id, %{"email" => @email}, nil)

      {:ok, %{inserted_user_role: user_role}} = Apps.create_user_env_role(user_access.id, user.id, "admin")

      assert user_role.access_id == user_access.id
      assert user_role.role == "admin"
    end

    test "user environment role but already exists", %{app: _app, env: env, user: user} do
      {:ok, %{inserted_user_access: user_access}} = Apps.create_user_env_access(env.id, %{"email" => @email}, nil)
      Apps.create_user_env_role(user_access.id, user.id, "admin")

      error = Apps.create_user_env_role(user_access.id, user.id, "admin")

      assert {:error, :inserted_user_role, _failed_value, _changes_so_far} = error
    end
  end

  describe "delete" do
    test "user environment role successfully", %{app: _app, env: env, user: user} do
      {:ok, %{inserted_user_access: created_user_access}} =
        Apps.create_user_env_access(env.id, %{"email" => @email}, nil)

      {:ok, %{inserted_user_role: _user_role}} = Apps.create_user_env_role(created_user_access.id, user.id, "admin")

      {1, _} = Apps.delete_user_env_role(created_user_access.id, "admin")

      [user_access] = Apps.all_user_env_access_and_roles(env.id)

      assert [] == user_access.roles
    end

    test "user environment role unexisting", %{app: _app, env: env, user: _user} do
      {:ok, %{inserted_user_access: user_access}} = Apps.create_user_env_access(env.id, %{"email" => @email}, nil)

      error = Apps.delete_user_env_role(user_access.id, "admin")

      assert {0, _} = error
    end
  end
end
