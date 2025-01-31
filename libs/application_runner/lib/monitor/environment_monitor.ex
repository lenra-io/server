defmodule ApplicationRunner.Monitor.EnvironmentMonitor do
  @moduledoc """
    The EnvironmentMonitor monitor environment supervisor.
  """
  alias ApplicationRunner.ApplicationServices

  use GenServer

  require Logger

  def monitor(pid, metadata) do
    GenServer.call(__MODULE__, {:monitor, pid, metadata})
  rescue
    e ->
      Logger.error("#{__MODULE__} fail in monitor with metadata #{inspect(metadata)} and error: #{inspect(e)}")
  end

  def start_link(_opts) do
    Logger.debug("Start #{__MODULE__}")
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:monitor, pid, metadata}, _from, state) do
    Logger.debug("#{__MODULE__} monitor #{inspect(pid)} with metadata #{inspect(metadata)}")

    Process.monitor(pid)

    {:reply, :ok, Map.put(state, pid, {metadata})}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {{metadata}, new_state} = Map.pop(state, pid)
    base_url = Application.fetch_env!(:application_runner, :faas_url)
    auth = Application.fetch_env!(:application_runner, :faas_auth)

    Logger.debug("#{__MODULE__} handle down #{inspect(pid)} with metadata #{inspect(metadata)}")

    min_scale = Map.get(metadata, :min_scale, 0)

    if Application.fetch_env!(:application_runner, :scale_to_zero) && min_scale == 0 do
      function_name = Map.get(metadata, :function_name)
      ApplicationServices.stop_app(function_name)
    end

    {:noreply, new_state}
  end
end
