defmodule ApplicationRunner.ModuleInjector do
  @moduledoc """
    Injector for the mock additionnal modules
  """
  def add_session_modules(_) do
    [ApplicationRunner.MockGenServer]
  end

  def add_env_modules(_) do
    [ApplicationRunner.MockGenServer]
  end
end
