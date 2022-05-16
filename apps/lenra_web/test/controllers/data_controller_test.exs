defmodule LenraWeb.DataControllerTest do
  @moduledoc """
    Test the `LenraWeb.DataController` module
  """

  use LenraWeb.ConnCase, async: false

  alias ApplicationRunner.SessionManagers

  alias Lenra.{
    Build,
    BuildServices,
    Deployment,
    Environment,
    EnvironmentServices,
    FaasStub,
    LenraApplicationServices,
    Repo,
    SessionStateServices
  }

  setup %{conn: conn} do
    %{env: env, app: app, session_id: session_id} = create_app_and_get_env()
    {:ok, %{conn: conn, env: env, app: app, session_id: session_id}}
  end

  defp create_app_and_get_env do
    {:ok, %{inserted_user: user}} = UserTestHelper.register_john_doe()

    {:ok, %{inserted_application: application, application_main_env: env}} =
      LenraApplicationServices.create(
        user.id,
        %{name: "stubapp", color: "FFFFFF", icon: 1}
      )

    {:ok, inserted_build} = Repo.insert(Build.new(user.id, application.id, 1, %{}))

    deploy(inserted_build.id, env.environment_id, user.id)

    env_preloaded =
      Environment
      |> Repo.get(env.environment_id)
      |> Repo.preload(:deployed_build)

    faas = FaasStub.create_faas_stub()
    lenra_env = Application.fetch_env!(:lenra, :lenra_env)
    url = "/function/#{lenra_env}-#{application.service_name}-#{inserted_build.build_number}"

    Bypass.stub(faas, "POST", url, &handle_request(&1))

    session_id = Ecto.UUID.generate()

    SessionManagers.start_session(
      session_id,
      env_preloaded.id,
      %{user: user, application: application, environment: env_preloaded, socket_pid: self()},
      %{application: application, environment: env_preloaded, user: user}
    )

    %{env: env_preloaded, app: application, session_id: session_id}
  end

  defp handle_request(conn) do
    Plug.Conn.resp(conn, 200, Jason.encode!(%{"manifest" => %{}}))
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

  describe "LenraWeb.DataController.create_2/1" do
    test "should create data if params valid", %{
      conn: conn,
      session_id: session_id
    } do
      token = SessionStateServices.fetch_token(session_id)

      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(Routes.datastore_path(conn, :create), %{
        "name" => "test"
      })

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(Routes.data_path(conn, :create, "test"), %{
          "name" => "toto"
        })

      assert %{
               "data" => %{
                 "inserted_data" => %{
                   "data" => %{
                     "_datastore" => "test",
                     "_id" => _id,
                     "_refBy" => [],
                     "_refs" => [],
                     "name" => "toto"
                   }
                 }
               }
             } = json_response(conn, 200)

      assert Map.has_key?(json_response(conn, 200), "data")
    end

    test "should return error if params not valid", %{
      conn: conn,
      session_id: session_id
    } do
      token = SessionStateServices.fetch_token(session_id)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> post(Routes.data_path(conn, :create, "test"), %{
          "name" => "toto"
        })

      assert json_response(conn, 400) == %{
               "errors" => [%{"code" => 27, "message" => "Datastore cannot be found"}],
               "success" => false
             }
    end
  end

  describe "LenraWeb.DataController.get_me_2/1" do
    test "should get data if params valid", %{
      conn: conn,
      session_id: session_id
    } do
      token = SessionStateServices.fetch_token(session_id)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(Routes.data_path(conn, :get_me))

      %{"email" => email} = conn.assigns.data.user_data.data["_user"]

      assert Map.has_key?(json_response(conn, 200), "data")
      assert "john.doe@lenra.fr" == email
    end
  end

  describe "LenraWeb.DataController.update_2/1" do
    test "should update data if params valid", %{
      conn: conn,
      env: env,
      session_id: session_id
    } do
      token = SessionStateServices.fetch_token(session_id)

      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(Routes.datastore_path(conn, :create), %{
        "name" => "test"
      })

      {:ok, %{inserted_data: data}} =
        Lenra.DataServices.create(env.id, %{"_datastore" => "test", "data" => %{"name" => "toto"}})

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(Routes.data_path(conn, :update, "test", data.id), %{
          "name" => "test"
        })

      assert %{
               "data" => %{
                 "updated_data" => %{
                   "data" => %{
                     "_datastore" => "test",
                     "_id" => _id,
                     "_refBy" => [],
                     "_refs" => [],
                     "name" => "test"
                   }
                 }
               }
             } = json_response(conn, 200)

      assert Map.has_key?(json_response(conn, 200), "data")
    end

    test "should return error if params not valid", %{
      conn: conn,
      session_id: session_id
    } do
      token = SessionStateServices.fetch_token(session_id)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> put(Routes.data_path(conn, :update, "test", -1), %{
          "data" => %{"name" => "test"}
        })

      assert json_response(conn, 400) == %{
               "errors" => [%{"code" => 28, "message" => "Data cannot be found"}],
               "success" => false
             }
    end
  end

  describe "LenraWeb.DataController.delete_1/1" do
    test "should delete data if id valid", %{
      conn: conn,
      env: env,
      session_id: session_id
    } do
      token = SessionStateServices.fetch_token(session_id)

      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{token}")
      |> post(Routes.datastore_path(conn, :create), %{
        "name" => "test"
      })

      {:ok, %{inserted_data: data}} =
        Lenra.DataServices.create(env.id, %{"_datastore" => "test", "data" => %{"name" => "toto"}})

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(Routes.data_path(conn, :delete, "test", data.id), %{
          "data" => %{"name" => "test"}
        })

      assert Map.has_key?(json_response(conn, 200), "data")
    end

    test "should return error if id invalid", %{
      conn: conn,
      env: _env,
      session_id: session_id
    } do
      token = SessionStateServices.fetch_token(session_id)

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(Routes.data_path(conn, :delete, "test", -1), %{
          "data" => %{"name" => "test"}
        })

      assert json_response(conn, 400) == %{
               "errors" => [%{"code" => 28, "message" => "Data cannot be found"}],
               "success" => false
             }
    end
  end
end
