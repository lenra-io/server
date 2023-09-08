# defmodule ApplicationRunner.ListenerCacheTest do
#   use ApplicationRunner.RepoCase, async: false

#   alias ApplicationRunner.{
#     EventHandler,
#     ListenersCache,
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
#     start_supervised({Finch, name: AppHttp})

#     {:ok, env} = Repo.insert(Environment.new())
#     {:ok, user} = Repo.insert(User.new(%{email: "test@test.te"}))

#     bypass = Bypass.open()

#     Bypass.stub(
#       bypass,
#       "POST",
#       "/function/test_function",
#       &handle_request(&1)
#     )

#     Application.put_env(:application_runner, :faas_url, "http://localhost:#{bypass.port}")

#     {:ok, pid} =
#       Session.Managers.start_session(
#         Ecto.UUID.generate(),
#         env.id,
#         %{
#           user_id: user.id,
#           function_name: "test_function",
#           assigns: %{socket_pid: self()}
#         },
#         %{
#           function_name: "test_function",
#           assigns: %{}
#         }
#       )

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

#     {:ok, %{session_state: :sys.get_state(pid)}}
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

#   test "test save_listener and fetch_listener", %{session_state: session_state} do
#     action = "go"
#     props = %{"value" => "ok"}

#     listener = %{
#       "action" => action,
#       "props" => props
#     }

#     code = Crypto.hash({action, props})

#     assert {:error, BusinessError.unknow_listener_code(code)} ==
#              ListenersCache.fetch_listener(session_state, code)

#     assert :ok == ListenersCache.save_listener(session_state, code, listener)
#     assert {:ok, listener} == ListenersCache.fetch_listener(session_state, code)
#   end
# end
