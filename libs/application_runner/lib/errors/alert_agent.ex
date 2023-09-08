defmodule ApplicationRunner.Errors.AlertAgent do
  @moduledoc """
    ApplicationRunner.Errors.AlertAgent manages Alert & Emergency errors
  """

  use Agent
  require Logger

  def start_link(%__struct__{} = error) do
    Logger.alert(error)

    alert_metadata = %{
      alert_sent: 1
    }

    Agent.start_link(fn -> alert_metadata end, name: {:via, :swarm, error})
  end

  def send_alert(agent, error) do
    Agent.update(agent, fn alert_metadata ->
      # If we have already sent less than 5 errors, send a new alert.
      if alert_metadata.alert_sent <= 5 do
        Logger.alert(error)
        Map.update(alert_metadata, :alert_sent, 1, fn value -> value + 1 end)
        # if we sent 5 alerts, send an emergency and reset the counter.
      else
        Logger.emergency(error)
        Map.update(alert_metadata, :alert_sent, 1, fn _value -> 0 end)
      end
    end)
  end
end
