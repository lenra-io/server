defmodule ApplicationRunner.Session.Events.OnSessionStart do
  @moduledoc """
    OnEnvStart task send listeners onEnvStart
  """

  use GenServer, restart: :transient

  require Logger

  @on_session_start_action "onSessionStart"

  def start_link(opts) do
    session_id = Keyword.fetch!(opts, :session_id)

    GenServer.start_link(__MODULE__, session_id)
  end

  def init(session_id) do
    Logger.debug("#{__MODULE__} run event for session_id: #{session_id}")

    case ApplicationRunner.EventHandler.send_session_event(
           session_id,
           @on_session_start_action,
           %{},
           %{}
         ) do
      :ok ->
        Logger.debug("#{__MODULE__} succesfully ran event for session_id: #{session_id}")
        {:ok, :ok, {:continue, :stop_me}}

      {:error, reason} when reason.reason != :error_404 ->
        Logger.warning("#{__MODULE__} cannot run event session_id: #{session_id}")
        {:stop, reason}

      # OnSessionstart may not be implemented
      {:error, reason} when reason.reason == :error_404 ->
        Logger.debug("#{__MODULE__} event not found for session_id: #{session_id}")
        {:ok, :ok, {:continue, :stop_me}}
    end
  end

  def handle_continue(:stop_me, state) do
    {:stop, :normal, state}
  end
end
