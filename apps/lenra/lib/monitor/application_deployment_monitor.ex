defmodule Lenra.Monitor.ApplicationDeploymentMonitor do
  @moduledoc """
    The application deployment monitor which monitors the time spent deploying an app.
  """

  use GenServer
  use SwarmNamed

  alias Lenra.Telemetry

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

    start_time = Map.get(metadata, :start_time)

    {:reply, :ok, Map.put(state, pid, {start_time, metadata})}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {{start_time, metadata}, new_state} = Map.pop(state, pid)

    Logger.debug("#{__MODULE__} handle down #{inspect(pid)} with metadata #{inspect(metadata)}")

    Telemetry.stop(:app_deployment, start_time, metadata)

    {:noreply, new_state}
  end
end
