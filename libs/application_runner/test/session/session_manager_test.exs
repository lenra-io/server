# defmodule ApplicationRunner.SessionManagerTest do
#   use ApplicationRunner.RepoCase, async: false

#   @moduledoc """
#     Test the `ApplicationRunner.SessionManagerTest` module
#   """

#   alias ApplicationRunner.{
#     EventHandler,
#     MockGenServer,
#     Repo,
#     Session
#   }

#   alias ApplicationRunner.Environments.Managers

#   alias ApplicationRunner.Contract.{
#     Environment,
#     User
#   }

#   @manifest %{"rootWidget" => "root"}
#   @ui %{"root" => %{"children" => [], "type" => "flex"}}

#   setup do
#     start_supervised(Managers)
#     start_supervised(Session.Managers)

#     {:ok, env} = Repo.insert(Environment.new())
#     {:ok, user} = Repo.insert(User.new(%{email: "test@test.te"}))

#     bypass = Bypass.open()
#     Bypass.stub(bypass, "POST", "/function/test_function", &handle_request(&1))

#     Application.put_env(:application_runner, :faas_url, "http://localhost:#{bypass.port}")

#     {:ok, %{user_id: user.id, env_id: env.id}}
#   end

#   defp handle_request(conn) do
#     {:ok, body, conn} = Plug.Conn.read_body(conn)

#     body_decoded =
#       if String.length(body) != 0 do
#         Jason.decode!(body)
#       else
#         ""
#       end

#     case body_decoded do
#       # Manifest no body
#       "" ->
#         Plug.Conn.resp(conn, 200, Jason.encode!(%{"manifest" => @manifest}))

#       # Listeners "listener" in body
#       %{"listener" => _listener} ->
#         Plug.Conn.resp(conn, 200, "")

#       # Widget data key
#       %{"data" => data, "props" => props, "widget" => widget} ->
#         Plug.Conn.resp(
#           conn,
#           200,
#           Jason.encode!(my_widget(data, props, widget))
#         )
#     end
#   end

#   test "SessionManager supervisor should exist and have the MockGenServer.", %{
#     user_id: user_id,
#     env_id: env_id
#   } do
#     assert {:ok, pid} =
#              Session.start_session(
#                Ecto.UUID.generate(),
#                env_id,
#                %{
#                  user_id: user_id,
#                  function_name: "test_function",
#                  assigns: %{socket_pid: self()}
#                },
#                %{
#                  function_name: "test_function",
#                  assigns: %{}
#                }
#              )

#     assert _pid =
#              Session.Supervisor.fetch_module_pid!(
#                :sys.get_state(pid).session_supervisor_pid,
#                MockGenServer
#              )

#     assert handler_pid =
#              Session.Supervisor.fetch_module_pid!(
#                :sys.get_state(pid).session_supervisor_pid,
#                EventHandler
#              )

#     # Wait for OnSessionStart
#     assert :ok = EventHandler.subscribe(handler_pid)

#     assert_receive({:event_finished, _listener, _res})

#     assert_receive({:event_finished, _listener, _res})

#     assert_receive({:send, :ui, @ui})
#   end

#   test "SessionManager supervisor should not have the NotExistGenServer", %{
#     user_id: user_id,
#     env_id: env_id
#   } do
#     assert {:ok, pid} =
#              Session.start_session(
#                Ecto.UUID.generate(),
#                env_id,
#                %{
#                  user_id: user_id,
#                  function_name: "test_function",
#                  assigns: %{socket_pid: self()}
#                },
#                %{
#                  function_name: "test_function",
#                  assigns: %{}
#                }
#              )

#     assert_raise(
#       RuntimeError,
#       "No such Module in SessionSupervisor. This should not happen.",
#       fn ->
#         Session.Supervisor.fetch_module_pid!(
#           :sys.get_state(pid).session_supervisor_pid,
#           NotExistGenServer
#         )
#       end
#     )

#     assert handler_pid =
#              Session.Supervisor.fetch_module_pid!(
#                :sys.get_state(pid).session_supervisor_pid,
#                EventHandler
#              )

#     # Wait for OnSessionStart
#     assert :ok = EventHandler.subscribe(handler_pid)

#     assert_receive({:event_finished, _listener, _res})

#     # Wait for Widget
#     assert :ok = EventHandler.subscribe(handler_pid)

#     assert_receive({:send, :ui, @ui})
#   end

#   def my_widget(_, _, _) do
#     %{
#       "type" => "flex",
#       "children" => []
#     }
#   end

#   describe "SessionManager.send_special_event/2" do
#     @tag mock: %{
#            widgets: %{
#              "root" => &__MODULE__.my_widget/3
#            }
#          }
#     test "Special listeners are optionnal. Nothing happen if not set." do
#       refute_receive({:ui, _})
#       refute_receive({:error, _})
#     end
#   end
# end
