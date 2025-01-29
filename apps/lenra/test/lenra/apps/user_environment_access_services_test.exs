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

  @email "test@lenra.io"
  @app_url_prefix "https://localhost:10000/app/invitations"

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
      assert [] == Apps.all_user_env_access(env.id)
    end

    test "one user access for environment", %{app: _app, env: env, user: _user} do
      Apps.create_user_env_access(env.id, %{"email" => @email}, nil)

      assert 1 ==
               env.id
               |> Apps.all_user_env_access()
               |> Enum.count()
    end
  end

  describe "create" do
    test "user environment access successfully", %{app: _app, env: env, user: _user} do
      Apps.create_user_env_access(env.id, %{"email" => @email}, nil)

      access =
        env.id
        |> Apps.all_user_env_access()
        |> Enum.at(0)

      assert access.environment_id == env.id
      assert access.email == @email
    end

    test "send email after invitation", %{app: app, env: env, user: _user} do
      {:ok, %{inserted_user_access: user_access}} = Apps.create_user_env_access(env.id, %{"email" => @email}, nil)

      app_link = "#{@app_url_prefix}/#{user_access.id}"

      email = EmailService.create_invitation_email(@email, app.name, app_link)

      assert_delivered_email(email)
    end

    test "user environment access but already exists", %{app: _app, env: env, user: _user} do
      Apps.create_user_env_access(env.id, %{"email" => @email}, nil)

      error = Apps.create_user_env_access(env.id, %{"email" => @email}, nil)

      assert {:error, :inserted_user_access, _failed_value, _changes_so_far} = error
    end

    test "user environment access for current user", %{app: _app, env: env, user: user} do
      error = Apps.create_user_env_access(env.id, %{"email" => user.email}, nil)

      assert {:error, %{reason: :cannot_add_creator_as_user, status_code: 403}} = error
    end

    test "user environment access but invalid params", %{app: _app, env: env, user: _user} do
      error = Apps.create_user_env_access(env.id + 1, %{"email" => ""}, nil)

      assert {:error, %{reason: :no_env_found, metadata: %{}, status_code: 404}} = error
    end
  end

  describe "create user env access from email" do
    test "successfully", %{app: _app, env: env, user: _user} do
      Apps.create_user_env_access(env.id, %{"email" => @email}, nil)

      access =
        env.id
        |> Apps.all_user_env_access()
        |> Enum.at(0)

      assert access.environment_id == env.id
      assert access.email == @email
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
    test "user environment access successfully", %{app: _app, env: env, user: _user} do
      {:ok, %{inserted_user_access: user_access}} = Apps.create_user_env_access(env.id, %{"email" => @email}, nil)

      Apps.UserEnvironmentAccess
      |> Repo.get_by(id: user_access.id)
      |> Apps.delete_user_env_access()

      assert [] == Apps.all_user_env_access(env.id)
    end
  end
end
