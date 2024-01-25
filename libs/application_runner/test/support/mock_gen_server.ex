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

defmodule ApplicationRunner.StateInjectedGenServer do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(state: state) do
    {:ok, state}
  end

  def handle_call({:set_state, new_state}, _from, state) do
    {:reply, {:ok}, new_state}
  end

  def handle_call(request, _from, state) do
    {:reply, state, state}
  end
end
