defmodule Lenra.Monitor.ApplicationDeploymentMonitor do
  @moduledoc """
    The application deployment monitor which monitors the time spent deploying an app.
  """

  use GenServer
  use SwarmNamed

  alias Lenra.Telemetry

  require Logger

  def monitor(application_id, metadata) do
    GenServer.call(__MODULE__, {:monitor, application_id, metadata})
  rescue
    e ->
      Logger.error("#{__MODULE__} fail in monitor with metadata #{inspect(metadata)} and error: #{inspect(e)}")
  end

  def stop(application_id, metadata) do
    GenServer.call(__MODULE__, {:stop, application_id, metadata})
  rescue
    e ->
      Logger.error("#{__MODULE__} fail in stop with metadata #{inspect(metadata)} and error: #{inspect(e)}")
  end

  def start_link(_opts) do
    Logger.debug("Start #{__MODULE__}")
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:monitor, application_id, metadata}, _from, state) do
    Logger.debug("#{__MODULE__} monitor #{inspect(application_id)} with metadata #{inspect(metadata)}")

    start_time = Map.get(metadata, :start_time)

    {:reply, :ok, Map.put(state, application_id, {start_time, metadata})}
  end

  def handle_info({:stop, application_id, _metadata}, state) do
    {{start_time, metadata}, new_state} = Map.pop(state, application_id)

    Logger.debug("#{__MODULE__} handle down #{inspect(application_id)} with metadata #{inspect(metadata)}")

    Telemetry.stop(:app_deployment, start_time, metadata)

    {:noreply, new_state}
  end
end
