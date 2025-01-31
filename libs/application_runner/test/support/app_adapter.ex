defmodule ApplicationRunner.FakeAppAdapter do
  @moduledoc """
    This adapter give ApplicationRunner the few function that he needs to work correctly.
  """
  @behaviour ApplicationRunner.Adapter

  @impl ApplicationRunner.Adapter
  def allow(_user_id, _app_name) do
    :ok
  end

  @impl ApplicationRunner.Adapter
  def get_function_name("env_" <> _env_id = name) do
    name
  end

  def get_function_name(_app_name) do
    "function_name"
  end

  @impl ApplicationRunner.Adapter
  def get_env_id("env_" <> suffix) do
    {env_id, ""} = Integer.parse(suffix)
    env_id
  end

  def get_env_id(_app_name) do
    1
  end

  @impl ApplicationRunner.Adapter
  def get_scale_options(_app_name) do
    %{scale_min: 0, scale_max: 1}
  end

  @impl ApplicationRunner.Adapter
  def resource_from_params(%{"connect_result" => connect_result}) do
    connect_result
  end

  def resource_from_params(_params) do
    {:ok, nil, ["guest"], "name", %{}}
  end
end
