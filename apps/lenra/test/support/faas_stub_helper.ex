defmodule Lenra.FaasStub do
  @moduledoc """
    Helper to generate stubbed apps for testing
  """
  use ExUnit.CaseTemplate

  def create_faas_stub do
    Bypass.open(port: 1234)
  end

  def stub_app(bypass, app_name, build_number) do
    lenra_env = Application.fetch_env!(:lenra, :lenra_env)
    url = "/function/#{lenra_env}-#{app_name}-#{build_number}"

    Bypass.stub(bypass, "POST", url, &handle_action(&1, app_name))

    {bypass, app_name}
  end

  def stub_app_resource(bypass, app_name, build_number) do
    lenra_env = Application.fetch_env!(:lenra, :lenra_env)
    url = "/function/#{lenra_env}-#{app_name}-#{build_number}"

    Bypass.stub(bypass, "POST", url, &handle_resource(&1, app_name))

    {bypass, app_name}
  end

  def expect_app_list_once(bypass, result) do
    expect_once("/system/functions", "GET", bypass, result)
  end

  def expect_get_function_once(bypass, result, service_name) do
    expect_once("/system/function/#{service_name}", "GET", bypass, result)
  end

  def expect_deploy_app_once(bypass, result) do
    expect_once("/system/functions", "POST", bypass, result)
  end

  def expect_delete_app_once(bypass, result) do
    expect_once("/system/functions", "DELETE", bypass, result)
  end

  defp expect_once(url, http_method, bypass, result) do
    Bypass.expect_once(bypass, http_method, url, fn conn ->
      case result do
        {:error, code, message} ->
          Plug.Conn.resp(conn, code, message)

        any ->
          Plug.Conn.resp(conn, 200, Jason.encode!(any))
      end
    end)

    bypass
  end

  @spec stub_action_once(tuple(), String.t(), map() | {:error, number(), String.t()}) :: tuple()
  def stub_action_once({_bypass, app_name} = app, action_code, result) do
    push(app_name, {action_code, result})
    app
  end

  def stub_resource_once({_bypass, app_name} = app, resource_name, result) do
    push(app_name, {resource_name, result})
    app
  end

  def stub_request_once({_bypass, app_name} = app, result) do
    push(app_name, {nil, result})
    app
  end

  defp handle_action(conn, app_name) do
    {_stored_action_code, result} = pop(app_name)

    case result do
      {:error, code, message} ->
        Plug.Conn.resp(conn, code, message)

      data ->
        Plug.Conn.resp(conn, 200, Jason.encode!(data))
    end
  end

  defp handle_resource(conn, app_name) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    %{"resource" => resource_name} = Jason.decode!(body)

    {stored_resource_name, result} = pop(app_name)
    assert stored_resource_name == resource_name

    case result do
      {:error, code, message} ->
        Plug.Conn.resp(conn, code, message)

      data ->
        Plug.Conn.resp(conn, 200, Jason.encode!(data))
    end
  end

  def init do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def pop(app_name) do
    case Agent.get(__MODULE__, &Map.get(&1, app_name, [])) do
      [head | tail] ->
        Agent.update(__MODULE__, &Map.put(&1, app_name, tail))
        head

      [] ->
        raise "App Stub Helper : No stub for app #{app_name}. You probably forgot a call case."
    end
  end

  def push(app_name, call_result) do
    Agent.update(__MODULE__, &Map.put(&1, app_name, Map.get(&1, app_name, []) ++ [call_result]))
  end
end
