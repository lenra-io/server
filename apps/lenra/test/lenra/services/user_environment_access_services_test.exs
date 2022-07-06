defmodule Lenra.UserEnvironmentAccessServicesTest do
  @moduledoc """
    Test the user environment access services
  """
  use Lenra.RepoCase, async: false
  use Bamboo.Test, shared: true

  alias Lenra.{
    EmailService,
    Repo,
    UserEnvironmentAccessServices
  }

  alias Lenra.Apps
  alias Lenra.Apps.{App, Environment}

  alias Lenra.Accounts

  @app_url_prefix "https://localhost:10000/app"

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

    %{app: Enum.at(Repo.all(App), 0), env: Enum.at(Repo.all(Environment), 0)}
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

    test "send email after invitation", %{app: app, env: env} do
      UserEnvironmentAccessServices.create(env.id, %{"user_id" => app.creator_id})

      user = Accounts.get_user(app.creator_id)
      app_link = "#{@app_url_prefix}/#{app.service_name}"

      email = EmailService.create_invitation_email(user.email, app.name, app_link)

      assert_delivered_email(email)
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

  describe "create user env access from email" do
    test "successfully", %{app: app, env: env} do
      user = Accounts.get_user(app.creator_id)
      UserEnvironmentAccessServices.create(env.id, %{"email" => user.email})

      access =
        env.id
        |> UserEnvironmentAccessServices.all()
        |> Enum.at(0)

      assert access.environment_id == env.id
      assert access.user_id == app.creator_id
    end

    test "unknown email", %{app: _app, env: env} do
      assert {:error, :user, %LenraCommon.Errors.TechnicalError{reason: :error_404}, _value} =
               UserEnvironmentAccessServices.create(env.id, %{"email" => "unknown@lenra.io"})

      access =
        env.id
        |> UserEnvironmentAccessServices.all()

      assert access == []
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
