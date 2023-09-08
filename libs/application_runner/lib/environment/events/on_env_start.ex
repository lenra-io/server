defmodule ApplicationRunner.Environment.Events.OnEnvStart do
  @moduledoc """
    OnEnvStart Event send listeners onEnvStart
  """

  use GenServer, restart: :transient

  @on_env_start_action "onEnvStart"

  @spec start_link(keyword) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    env_id = Keyword.fetch!(opts, :env_id)

    GenServer.start_link(__MODULE__, env_id)
  end

  def init(env_id) do
    case ApplicationRunner.EventHandler.send_env_event(env_id, @on_env_start_action, %{}, %{}) do
      :ok ->
        {:ok, :ok, {:continue, :stop_me}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def handle_continue(:stop_me, state) do
    {:stop, :normal, state}
  end
end
