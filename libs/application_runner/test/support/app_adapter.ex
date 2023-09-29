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
  def get_function_name(_app_name) do
    "function_name"
  end

  @impl ApplicationRunner.Adapter
  def get_env_id(_app_name) do
    1
  end

  @impl ApplicationRunner.Adapter
  def resource_from_params(_params) do
    {:ok, 1, "name", %{}}
  end
end
