defmodule ApplicationRunner.Telemetry do
  @moduledoc """
    The module for ApplicationRunner Telemetry
  """
  @doc """
    Sends a `:start` event with Telemetry.
    Returns `start_time` which is the monotonic time of the system, in the `:native` type, when calling this function.
    These parameters should be passed in metadata:
        * user_id: :integer
        * env_id: :integer
  """
  def start(event, meta \\ %{}, extra_mesurements \\ %{}) do
    start_time = DateTime.utc_now()

    :telemetry.execute(
      [:application_runner, event, :start],
      Map.merge(extra_mesurements, %{system_time: System.system_time(), start_time: start_time}),
      meta
    )

    start_time
  end

  @doc """
    Sends a `:stop` event with Telemetry.
  """
  def stop(event, start_time, meta \\ %{}, extra_measurements \\ %{}) do
    end_time = DateTime.utc_now()

    :telemetry.execute(
      [:application_runner, event, :stop],
      Map.merge(extra_measurements, %{
        duration: DateTime.diff(end_time, start_time),
        end_time: end_time
      }),
      meta
    )
  end

  @doc """
    Sends a `:event` event with Telemetry.
  """
  def event(event, meta \\ %{}, measurements \\ %{}) do
    :telemetry.execute(
      [:application_runner, event, :event],
      measurements,
      meta
    )
  end
end
