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

  def update_scale_options(pid, scale_opts) do
    GenServer.call(__MODULE__, {:update_scale_opts, pid, scale_opts})
  rescue
    e ->
      Logger.error(
        "#{__MODULE__} fail in updating scale options with scale_opts #{inspect(scale_opts)} and error: #{inspect(e)}"
      )
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

  def handle_call({:update_scale_opts, pid, scale_opts}, _from, state) do
    {metadata} = Map.get(state, pid)

    Logger.debug(
      "#{__MODULE__} update scale options #{inspect(pid)} with metadata #{inspect(metadata)} and scale_opts #{inspect(scale_opts)}"
    )

    metadata =
      metadata
      |> Map.put(:scale_min, scale_opts.min)
      |> Map.put(:scale_max, scale_opts.max)

    {:reply, :ok, Map.put(state, pid, {metadata})}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    {{metadata}, new_state} = Map.pop(state, pid)

    Logger.debug("#{__MODULE__} handle down #{inspect(pid)} with metadata #{inspect(metadata)}")

    metadata
    |> Map.get(:function_name)
    |> ApplicationServices.stop_app(Map.get(metadata, :scale_min, 0))

    {:noreply, new_state}
  end
end
