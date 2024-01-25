defmodule Lenra.Apps.AppsTest do
  @moduledoc """
    Test the application services
  """

  use Lenra.RepoCase, async: false

  alias Lenra.Apps
  alias Lenra.Errors.TechnicalError
  alias Lenra.Repo

  @tag :register_user
  test "fetch_app", %{user: user} do
    params = %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    }

    case Apps.create_app(user.id, params) do
      {:ok, %{inserted_application: app}} ->
        assert {:ok, _app} = Apps.fetch_app(app.id)

      {:error, _} ->
        assert false, "adding app failed"
    end
  end

  describe "all_apps_user_opened" do
    @tag :register_user
    test "should work properly", %{user: user} do
      assert {:ok, %{inserted_application: app}} =
               Apps.create_app(user.id, %{
                 name: "mine-sweeper",
                 color: "FFFFFF",
                 icon: "60189"
               })

      # This app is not opened by the user and should not appear in the result list.
      assert {:ok, %{inserted_application: _app}} =
               Apps.create_app(user.id, %{
                 name: "mine-sweeper2",
                 color: "FFFFFF",
                 icon: "60189"
               })

      env_id = Repo.preload(app, :main_env).main_env.environment_id

      start_supervised({ApplicationRunner.EventHandler, %{mode: :session, id: env_id}})

      start_supervised(
        {ApplicationRunner.Session.MetadataAgent,
         %ApplicationRunner.Session.Metadata{
           session_id: 1,
           env_id: env_id,
           user_id: user.id,
           roles: ["user"],
           function_name: "",
           context: %{}
         }}
      )

      start_supervised(
        {ApplicationRunner.Session.Events.OnUserFirstJoin,
         [
           session_id: 1,
           env_id: env_id,
           user_id: user.id
         ]}
      )

      assert [%Lenra.Apps.App{name: "mine-sweeper"}] = Apps.all_apps_user_opened(user.id)
    end

    @tag :register_user
    test "with multiple apps opened", %{user: user} do
      assert {:ok, %{inserted_application: app}} =
               Apps.create_app(user.id, %{
                 name: "mine-sweeper",
                 color: "FFFFFF",
                 icon: "60189"
               })

      assert {:ok, %{inserted_application: app2}} =
               Apps.create_app(user.id, %{
                 name: "mine-sweeper2",
                 color: "FFFFFF",
                 icon: "60189"
               })

      env_id = Repo.preload(app, :main_env).main_env.environment_id
      env_id2 = Repo.preload(app2, :main_env).main_env.environment_id

      start_supervised({ApplicationRunner.EventHandler, %{mode: :session, id: env_id}})

      start_supervised(
        {ApplicationRunner.Session.MetadataAgent,
         %ApplicationRunner.Session.Metadata{
           session_id: 1,
           env_id: env_id,
           user_id: user.id,
            roles: ["user"],
           function_name: "",
           context: %{}
         }}
      )

      start_supervised(
        {ApplicationRunner.Session.Events.OnUserFirstJoin,
         [
           session_id: 1,
           env_id: env_id,
           user_id: user.id
         ]}
      )

      start_supervised({ApplicationRunner.EventHandler, %{mode: :session, id: env_id2}})

      start_supervised(
        {ApplicationRunner.Session.MetadataAgent,
         %ApplicationRunner.Session.Metadata{
           session_id: 1,
           env_id: env_id2,
           user_id: user.id,
            roles: ["user"],
           function_name: "",
           context: %{}
         }}
      )

      start_supervised(
        {ApplicationRunner.Session.Events.OnUserFirstJoin,
         [
           session_id: 1,
           env_id: env_id2,
           user_id: user.id
         ]}
      )

      assert [%Lenra.Apps.App{name: "mine-sweeper"}, %Lenra.Apps.App{name: "mine-sweeper2"}] =
               Apps.all_apps_user_opened(user.id)
    end
  end

  @tag :register_user
  test "fetch app by", %{user: user} do
    params = %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    }

    case Apps.create_app(user.id, params) do
      {:ok, %{inserted_application: app}} ->
        assert {:ok, _value} = Apps.fetch_app_by(name: app.name)

      {:error, _} ->
        assert false, "adding app failed"
    end
  end

  @tag :register_user
  test "delete app", %{user: user} do
    params = %{
      name: "mine-sweeper",
      color: "FFFFFF",
      icon: "60189"
    }

    {:ok, %{inserted_application: app}} = Apps.create_app(user.id, params)

    assert {:ok, _app} = Apps.fetch_app_by(name: "mine-sweeper")

    Apps.delete_app(app)

    assert TechnicalError.error_404_tuple() ==
             Apps.fetch_app_by(name: "mine-sweeper")
  end
end
