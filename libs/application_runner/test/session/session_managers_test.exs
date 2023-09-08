# defmodule ApplicationRunner.SessionManagersTest do
#   use ApplicationRunner.RepoCase, async: false

#   @moduledoc """
#     Test the `ApplicationRunner.SessionManagersTest` module
#   """

#   alias ApplicationRunner.{
#     EventHandler,
#     Repo,
#     Session
#   }

#   alias ApplicationRunner.Environments.Managers

#   alias ApplicationRunner.Contract.{
#     Environment,
#     User
#   }

#   alias ApplicationRunner.Errors.BusinessError

#   @manifest %{"rootWidget" => "root"}
#   @ui %{"root" => %{"children" => [], "type" => "flex"}}

#   setup do
#     start_supervised(Managers)
#     start_supervised(Session.Managers)

#     bypass = Bypass.open()

#     Bypass.stub(
#       bypass,
#       "POST",
#       "/function/test_function",
#       &handle_request(&1)
#     )

#     Application.put_env(:application_runner, :faas_url, "http://localhost:#{bypass.port}")

#     {:ok, env} = Repo.insert(Environment.new())
#     {:ok, user} = Repo.insert(User.new(%{email: "test@test.te"}))
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

#       # Listeners "action" in body
#       %{"action" => _action} ->
#         Plug.Conn.resp(conn, 200, "")

#       # Widget data key
#       %{"data" => _data, "props" => _props, "widget" => _widget} ->
#         Plug.Conn.resp(
#           conn,
#           200,
#           Jason.encode!(%{"children" => [], "type" => "flex"})
#         )
#     end
#   end

#   test "Can start one Session", %{user_id: user_id, env_id: env_id} do
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

#     assert handler_pid =
#              Session.Supervisor.fetch_module_pid!(
#                :sys.get_state(pid).session_supervisor_pid,
#                EventHandler
#              )

#     # Wait for OnSessionStart
#     assert :ok = EventHandler.subscribe(handler_pid)

#     assert_receive({:event_finished, _action, _res})

#     assert_receive({:event_finished, _action, _res})

#     assert_receive({:send, :ui, @ui})
#   end

#   test "Can start multiple Sessions", %{user_id: user_id, env_id: env_id} do
#     1..10
#     |> Enum.to_list()
#     |> Enum.each(fn _ ->
#       assert {:ok, pid} =
#                Session.start_session(
#                  Ecto.UUID.generate(),
#                  env_id,
#                  %{
#                    user_id: user_id,
#                    function_name: "test_function",
#                    assigns: %{socket_pid: self()}
#                  },
#                  %{
#                    function_name: "test_function",
#                    assigns: %{}
#                  }
#                )

#       assert handler_pid =
#                Session.Supervisor.fetch_module_pid!(
#                  :sys.get_state(pid).session_supervisor_pid,
#                  EventHandler
#                )

#       # Wait for OnSessionStart
#       assert :ok = EventHandler.subscribe(handler_pid)

#       assert_receive({:event_finished, _action, _res})

#       assert_receive({:event_finished, _action, _res})

#       assert_receive({:send, :ui, @ui})
#     end)
#   end

#   test "Can start one session and get it after", %{user_id: user_id, env_id: env_id} do
#     session_id = Ecto.UUID.generate()

#     assert {:error, BusinessError.session_not_started({:session, session_id})} ==
#              Session.Managers.fetch_session_manager_pid(session_id)

#     assert {:ok, pid} =
#              Session.start_session(
#                session_id,
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

#     assert {:ok, ^pid} = Session.Managers.fetch_session_manager_pid(session_id)

#     assert handler_pid =
#              Session.Supervisor.fetch_module_pid!(
#                :sys.get_state(pid).session_supervisor_pid,
#                EventHandler
#              )

#     # Wait for OnSessionStart
#     assert :ok = EventHandler.subscribe(handler_pid)

#     assert_receive({:event_finished, _action, _res})

#     assert_receive({:event_finished, _action, _res})

#     assert_receive({:send, :ui, @ui})
#   end

#   test "Cannot start same session twice", %{user_id: user_id, env_id: env_id} do
#     session_id = Ecto.UUID.generate()

#     assert {:ok, pid} =
#              Session.start_session(
#                session_id,
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

#     assert handler_pid =
#              Session.Supervisor.fetch_module_pid!(
#                :sys.get_state(pid).session_supervisor_pid,
#                EventHandler
#              )

#     # Wait for OnSessionStart
#     assert :ok = EventHandler.subscribe(handler_pid)

#     assert_receive({:event_finished, _action, _res})

#     assert_receive({:event_finished, _action, _res})

#     assert_receive({:send, :ui, @ui})

#     assert {:error, {:already_started, ^pid}} =
#              Session.start_session(
#                session_id,
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
#   end
# end
