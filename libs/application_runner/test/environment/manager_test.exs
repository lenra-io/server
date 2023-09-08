# defmodule ApplicationRunner.Environments.ManagerTest do
#   use ApplicationRunner.RepoCase, async: false

#   @moduledoc """
#     Test the `ApplicationRunner.AppManager` module
#   """

#   alias ApplicationRunner.{
#     MockGenServer,
#     Repo
#   }

#   alias ApplicationRunner.Environments.{
#     Manager,
#     Managers,
#     Supervisor
#   }

#   alias ApplicationRunner.Contract.Environment

#   @manifest %{"rootWidget" => "root"}

#   setup do
#     start_supervised(Managers)
#     start_supervised({Finch, name: AppHttp})

#     bypass = Bypass.open()
#     Bypass.stub(bypass, "POST", "/function/test_function", &handle_request(&1))

#     Application.put_env(:application_runner, :faas_url, "http://localhost:#{bypass.port}")

#     {:ok, env} = Repo.insert(Environment.new())
#     {:ok, env_id: env.id}
#   end

#   defp handle_request(conn) do
#     Plug.Conn.resp(conn, 200, Jason.encode!(%{"manifest" => %{"rootWidget" => "root"}}))
#   end

#   test "EnvManager supervisor should be started and have MockGenServer in childs.", %{
#     env_id: env_id
#   } do
#     assert {:ok, pid} =
#              Managers.start_env(env_id, %{
#                env_id: env_id,
#                function_name: "test_function",
#                assigns: %{}
#              })

#     env_state = :sys.get_state(pid)

#     assert is_pid(Supervisor.fetch_module_pid!(env_state.env_supervisor_pid, MockGenServer))

#     assert :ok = Manager.wait_until_ready(env_id)
#   end

#   test "EnvManager supervisor should be started and dont have MockGenServer in childs", %{
#     env_id: env_id
#   } do
#     assert {:ok, pid} =
#              Managers.start_env(env_id, %{
#                env_id: env_id,
#                function_name: "test_function",
#                assigns: %{}
#              })

#     env_state = :sys.get_state(pid)

#     assert_raise(
#       RuntimeError,
#       "No such Module in EnvSupervisor. This should not happen.",
#       fn -> Supervisor.fetch_module_pid!(env_state.env_supervisor_pid, NotExistGenServer) end
#     )

#     assert :ok = Manager.wait_until_ready(env_id)
#   end

#   test "get_manifest call the get_manifest of the adapter", %{env_id: env_id} do
#     assert {:ok, _pid} =
#              Managers.start_env(env_id, %{
#                env_id: env_id,
#                function_name: "test_function",
#                assigns: %{}
#              })

#     assert @manifest == Manager.get_manifest(env_id)

#     assert :ok = Manager.wait_until_ready(env_id)
#   end

#   test "EnvManager should stop if EnvSupervisor is killed.", %{env_id: env_id} do
#     assert {:ok, pid} =
#              Managers.start_env(env_id, %{
#                env_id: env_id,
#                function_name: "test_function",
#                assigns: %{}
#              })

#     env_state = :sys.get_state(pid)
#     env_supervisor_pid = Map.fetch!(env_state, :env_supervisor_pid)
#     assert Process.alive?(env_supervisor_pid)
#     assert Process.alive?(pid)

#     assert :ok = Manager.wait_until_ready(env_id)

#     Process.exit(env_supervisor_pid, :kill)
#     # Wait a little for process stoped
#     Process.sleep(100)
#     assert not Process.alive?(env_supervisor_pid)
#     assert not Process.alive?(pid)
#   end

#   test "EnvManager should exist in Swarm group :envs", %{env_id: env_id} do
#     assert {:ok, pid} =
#              Managers.start_env(env_id, %{
#                env_id: env_id,
#                function_name: "test_function",
#                assigns: %{}
#              })

#     assert Enum.member?(Swarm.members(:envs), pid)
#     assert :ok = Manager.wait_until_ready(env_id)
#   end
# end
