defmodule ApplicationRunner.MockGenServer do
  @moduledoc """
    Gen server mock for testing purpose.
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(_) do
    {:ok, %{}}
  end
end
