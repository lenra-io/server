defmodule Lenra.Monitor.ApplicationDeploymentMonitor do
  @moduledoc """
    The application deployment monitor which monitors the time spent deploying an app.
  """

  use GenServer
  use SwarmNamed

  alias Lenra.Telemetry

  require Logger

  def monitor(application_id, build_id) do
    GenServer.call(__MODULE__, {:monitor, application_id, build_id})
  rescue
    e ->
      Logger.error(
        "#{__MODULE__} fail in monitor with application_id #{application_id}, build_id #{build_id} and error: #{inspect(e)}"
      )
  end

  def stop(build_id) do
    GenServer.call(__MODULE__, {:stop, build_id})
  rescue
    e ->
      Logger.error(
        "#{__MODULE__} fail in stop with build_id #{build_id} and error: #{inspect(e)}"
      )
  end

  def start_link(_opts) do
    Logger.debug("Start #{__MODULE__}")
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:monitor, application_id, build_id}, _from, state) do
    Logger.debug("#{__MODULE__} monitor #{inspect(application_id)} with build_id #{build_id}")

    start_time = Telemetry.start(:app_deployment, %{build_id: build_id})

    {:reply, :ok, Map.put(state, build_id, {application_id, start_time})}
  end

  def handle_info({:stop, build_id}, state) do
    {{application_id, start_time}, new_state} = Map.pop(state, build_id)

    Logger.debug("#{__MODULE__} handle down #{inspect(application_id)} with build_id #{build_id}")

    Telemetry.stop(:app_deployment, start_time, %{build_id: build_id})

    {:noreply, new_state}
  end
end
