defmodule Lenra.Telemetry do
  @moduledoc """
    The module for Lenra Telemetry
  """
  @doc """
    Sends a `:start` event with Telemetry.

    Returns `start_time` which is the monotonic time of the system, in the `:native` type, when calling this function.
  """
  def start(event, meta \\ %{}, extra_mesurements \\ %{}) do
    start_time = System.monotonic_time()

    :telemetry.execute(
      [:lenra, event, :start],
      Map.merge(extra_mesurements, %{system_time: System.system_time()}),
      meta
    )

    start_time
  end

  @doc """
    Sends a `:stop` event with Telemetry. These parameters should be passed in metadata:

        * user_id: :integer
        * app_name: :string
  """
  def stop(event, start_time, meta \\ %{}, extra_measurements \\ %{}) do
    end_time = System.monotonic_time()

    :telemetry.execute(
      [:lenra, event, :stop],
      Map.merge(extra_measurements, %{duration: end_time - start_time}),
      meta
    )
  end

  @doc """
    Sends a `:event` event with Telemetry.
  """
  def event(event, meta \\ %{}, measurements \\ %{}) do
    :telemetry.execute(
      [:lenra, event, :event],
      measurements,
      meta
    )
  end
end
