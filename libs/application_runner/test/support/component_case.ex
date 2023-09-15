defmodule ApplicationRunner.ComponentCase do
  @moduledoc """
    This is a ExUnit test case with some setup that allow simpler unit test on JSON UI.

    ```
      use ApplicationRunner.ComponentCase
    ```
  """
  defmacro __using__(_opts) do
    quote do
      use ApplicationRunner.RepoCase, async: false

      alias ApplicationRunner.{
        ApplicationRunnerAdapter,
        Environments,
        EventHandler,
        FaasStub,
        Repo,
        Session,
        User
      }

      alias ApplicationRunner.Environments.{Manager, Managers}

      @manifest %{"lenra" =>
        %{
          "routes" => [
            %{
              "path" => "/",
              "view" => %{
                "_type" => "view",
                "name" => "root"
              }
            }
          ]
        }
      }

      setup context do
        start_supervised(EnvManagers)
        start_supervised(Session.Managers)
        start_supervised(ApplicationRunnerAdapter)
        start_supervised({Finch, name: AppHttp})
        start_supervised(ApplicationRunner.JsonSchemata)

        session_id = Ecto.UUID.generate()

        if context[:mock] != nil do
          ApplicationRunnerAdapter.set_mock(context[:mock])
        end

        bypass = Bypass.open()
        Bypass.stub(bypass, "POST", "/function/test_function", &handle_request(&1))

        Application.put_env(:application_runner, :faas_url, "http://localhost:#{bypass.port}")

        {:ok, env} = Repo.insert(Environment.new())
        {:ok, user} = Repo.insert(User.new("test@test.te"))

        {:ok, pid} =
          Session.start_session(
            Ecto.UUID.generate(),
            env.id,
            %{
              user_id: user.id,
              function_name: "test_function",
              assigns: %{socket_pid: self()}
            },
            %{
              function_name: "test_function",
              assigns: %{}
            }
          )

        session_state = :sys.get_state(pid)

        assert handler_pid =
                 Session.Supervisor.fetch_module_pid!(
                   session_state.session_supervisor_pid,
                   EventHandler
                 )

        on_exit(fn ->
          EnvManagers.stop_env(env.id)
        end)

        %{session_state: session_state, session_pid: pid, session_id: session_id, env_id: env.id}
      end

      defp handle_request(conn) do
        {:ok, body, conn} = Plug.Conn.read_body(conn)

        body_decoded =
          if String.length(body) != 0 do
            Jason.decode!(body)
          else
            ""
          end

        case body_decoded do
          # Manifest no body
          "" ->
            Plug.Conn.resp(conn, 200, Jason.encode!(@manifest))

          # Listeners "listener" in body
          %{"listener" => _listener} ->
            Plug.Conn.resp(conn, 200, "")

          # view data key
          %{"data" => data, "props" => props, "view" => view} ->
            {:ok, view} = ApplicationRunnerAdapter.get_view(%{}, view, data, props)

            Plug.Conn.resp(
              conn,
              200,
              Jason.encode!(view)
            )
        end
      end

      def mock_root_and_run(json, env_id) do
        ApplicationRunnerAdapter.set_mock(%{views: %{"root" => fn _, _ -> json end}})
        EnvManager.reload_all_ui(env_id)
      end

      defmacro assert_success(expected) do
        quote do
          assert_receive {:send, :ui, %{"root" => res}}
          assert unquote(expected) = res
        end
      end

      defmacro assert_error(expected) do
        quote do
          assert_receive {:send, :error, res}
          assert res = unquote(expected)
        end
      end
    end
  end
end
