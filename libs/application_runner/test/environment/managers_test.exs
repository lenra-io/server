# defmodule ApplicationRunner.Environments.ManagersTest do
#   use ApplicationRunner.RepoCase, async: false

#   @moduledoc """
#     Test the `ApplicationRunner.EnvManagers` module
#   """

#   alias ApplicationRunner.Repo

#   alias ApplicationRunner.Contract.Environment

#   alias ApplicationRunner.Environments.{Manager, Managers}

#   alias ApplicationRunner.Errors.BusinessError

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
#     Plug.Conn.resp(conn, 200, Jason.encode!(%{"manifest" => %{}}))
#   end

#   test "Can start one Env", %{env_id: env_id} do
#     assert {:ok, _} =
#              Managers.start_env(env_id, %{
#                function_name: "test_function",
#                assigns: %{}
#              })

#     assert :ok = Manager.wait_until_ready(env_id)
#   end

#   test "Can start multiple Envs", %{env_id: _env_id} do
#     1..10
#     |> Enum.to_list()
#     |> Enum.each(fn _ ->
#       {:ok, env} = Repo.insert(Environment.new())

#       assert {:ok, _} =
#                Managers.start_env(env.id, %{
#                  function_name: "test_function",
#                  assigns: %{}
#                })

#       assert :ok = Manager.wait_until_ready(env.id)
#     end)
#   end

#   test "Can start one Env and get it after", %{env_id: env_id} do
#     assert {:error, BusinessError.env_not_started()} == Managers.fetch_env_manager_pid(env_id)

#     assert {:ok, pid} =
#              Managers.start_env(env_id, %{
#                function_name: "test_function",
#                assigns: %{}
#              })

#     assert {:ok, ^pid} = Managers.fetch_env_manager_pid(env_id)
#     assert :ok = Manager.wait_until_ready(env_id)
#   end

#   test "Cannot start same env twice", %{env_id: env_id} do
#     assert {:ok, pid} =
#              Managers.start_env(env_id, %{
#                function_name: "test_function",
#                assigns: %{}
#              })

#     assert :ok = Manager.wait_until_ready(env_id)

#     assert {:error, {:already_started, ^pid}} =
#              Managers.start_env(env_id, %{
#                function_name: "test_function",
#                assigns: %{}
#              })
#   end
# end
