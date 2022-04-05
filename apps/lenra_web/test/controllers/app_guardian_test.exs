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
    LenraApplicationServices,
    OpenfaasServices,
    FaasStub,
    Repo
  }

  setup %{conn: conn} do
    %{env: env, app: app, session_id: session_id} = create_app_and_get_env()
    {:ok, %{conn: conn, env: env, app: app, session_id: session_id}}
  end

  defp create_app_and_get_env() do
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
    lenra_env = Application.fetch_env!(:lenra, :lenra_env)
    url = "/function/#{lenra_env}-#{application.service_name}-#{inserted_build.build_number}"

    Bypass.stub(faas, "POST", url, &handle_request(&1))

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

  defp handle_request(conn) do
    case length(conn.req_headers) do
      4 ->
        %{"manifest" => %{}}

      5 ->
        post(
          conn,
          Routes.data_path(conn, :create, %{"datastore" => "test", "data" => %{"name" => "toto"}})
        )
    end
  end

  test "request should pass if token valid", %{conn: _conn, env: env, app: app, session_id: session_id} do
    assert %{assigns: %{message: "Your token is invalid."}} !=
             OpenfaasServices.run_listener(app, env, "InitData", %{}, %{}, %{}, session_id)
  end

  test "request should return error if token invalid", %{
    conn: conn,
    env: env,
    app: app,
    session_id: session_id
  } do
    OpenfaasServices.run_listener(app, env, "InitData", %{}, %{}, %{}, session_id)

    {:ok, token, _claims} =
      session_id
      |> Lenra.AppGuardian.encode_and_sign()

    conn =
      Map.put(conn, :req_headers, [
        {"Content-Type", "application/json"},
        {"authorization", "Bearer #{token}, Basic YWRtaW46M2kwREc4NTdLWlVaODQ3R0pheW5qMXAwbQ=="}
      ])

    assert %{assigns: %{message: "Your token is invalid."}} =
             post(
               conn,
               Routes.data_path(conn, :create, %{})
             )
  end

  test "request should return error if token not found", %{conn: conn, env: _env, app: _app, session_id: _session_id} do
    assert %{assigns: %{message: "No token found in the request, please try again."}} =
             post(
               conn,
               Routes.data_path(conn, :create, %{})
             )
  end
end
