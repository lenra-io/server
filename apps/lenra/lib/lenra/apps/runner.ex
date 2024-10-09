defmodule Lenra.Apps.Runner do
  @moduledoc """
  Main API for running Lenra app
  """

  @type function_name :: String.t()

  @behaviour Lenra.Apps.Builder.Adapter

  @doc """
  Starts the Lenra app
  """
  @impl true
  @spec start(function_name) :: :ok | {:error, DeliveryError.t()}
  def start(function_name) do
    adapter().start(function_name)
  end

  # TODO: stop

  # TODO: deploy

  # TODO: remove

  # TODO: can_scale

  # TODO: scale

  # TODO: run

  defp adapter do
    Application.get_env(:lenra, :runner_adapter, Lenra.Apps.Runner.DockerAdapter)
  end
end
