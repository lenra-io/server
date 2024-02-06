defmodule ApplicationRunner.Session.Events.OnUserFirstJoin do
  @moduledoc """
    OnEnvStart task send listeners onEnvStart
  """

  use GenServer, restart: :transient

  alias ApplicationRunner.MongoStorage

  require Logger

  @on_user_first_join_action "onUserFirstJoin"

  def start_link(opts) do
    session_id = Keyword.fetch!(opts, :session_id)
    env_id = Keyword.fetch!(opts, :env_id)
    user_id = Keyword.fetch!(opts, :user_id)

    GenServer.start_link(__MODULE__, [session_id, env_id, user_id])
  end

  def init([session_id, env_id, user_id]) do
    Logger.debug("#{__MODULE__} run event for session_id: #{session_id} and user: #{user_id}")

    with false <- MongoStorage.has_user_link?(env_id, user_id),
         {:ok, _} <-
           MongoStorage.create_user_link(%{environment_id: env_id, user_id: user_id}),
         :ok <-
           ApplicationRunner.EventHandler.send_session_event(
             session_id,
             @on_user_first_join_action,
             %{},
             %{}
           ) do
      Logger.debug(
        "#{__MODULE__} succesfully ran event for session_id: #{session_id}, env_id: #{env_id} and user: #{user_id}"
      )

      {:ok, :ok, {:continue, :stop_me}}
    else
      true ->
        Logger.debug("#{__MODULE__} user already ran onUserFirstJoin for id: #{user_id}")
        {:ok, :ok, {:continue, :stop_me}}

      {:error, reason} ->
        Logger.warning(
          "#{__MODULE__} cannot run event session_id: #{session_id}, env_id: #{env_id} and user: #{user_id}"
        )

        {:stop, reason}
    end
  end

  def handle_continue(:stop_me, state) do
    {:stop, :normal, state}
  end
end
