defmodule LenraWeb.AppGuardianTest do
  @moduledoc """
    Test the `LenraWeb.DataController` module
  """

  use LenraWeb.ConnCase, async: true

  alias ApplicationRunner.SessionManagers

  alias Lenra.{
    Build,
    BuildServices,
    Deployment,
    Environment,
    EnvironmentServices,
    LenraApplication,
    LenraApplicationServices,
    OpenfaasServices,
    FaasStub,
    Repo
  }

  setup %{conn: conn} do
    %{env: env, app: app, session_id: session_id} = create_app_and_get_env(conn)
    {:ok, %{conn: conn, env: env, app: app, session_id: session_id}}
  end

  defp create_app_and_get_env(conn) do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    {:ok, %{inserted_application: application, inserted_main_env: env}} =
      LenraApplicationServices.create(
        user.id,
        %{name: "stubapp", color: "FFFFFF", icon: 1}
      )

    {:ok, inserted_build} = Repo.insert(Build.new(user.id, application.id, 1, %{}))

    deploy(inserted_build.id, env.id, user.id)

    env = Repo.get(Environment, env.id) |> Repo.preload(:deployed_build)

    faas = FaasStub.create_faas_stub()
    app = FaasStub.stub_app(faas, application.service_name, inserted_build.build_number)

    FaasStub.stub_action_once(app, "", %{"manifest" => %{}})

    session_id = Ecto.UUID.generate()

    SessionManagers.start_session(
      session_id,
      env.id,
      %{user: user, application: application, environment: env},
      %{application: application, environment: env}
    )

    %{env: env, app: application, session_id: session_id}
  end

  defp deploy(build_id, env_id, publisher_id) do
    build =
      build_id
      |> BuildServices.get()
      |> Repo.preload(:application)

    env = EnvironmentServices.get(env_id)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:updated_env, Ecto.Changeset.change(env, deployed_build_id: build_id))
    |> Ecto.Multi.insert(
      :inserted_deployment,
      Deployment.new(build.application.id, env_id, build_id, publisher_id, %{})
    )
    |> Repo.transaction()
  end

  test "create data if token valid", %{conn: conn, env: env, app: app, session_id: session_id} do
    FaasStub.stub_action_once(
      app,
      "InitData",
      post(
        conn,
        Routes.data_path(conn, :create, %{
          "name" => "test",
          "color" => "ffffff",
          "icon" => 31
        })
      )
    )

    OpenfaasServices.run_listener(app, env, "InitData", %{}, %{}, %{}, session_id)
  end

  test "should return error if params not valid" do
  end
end
