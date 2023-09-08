defmodule ApplicationRunner.EventHandler do
  @moduledoc """
    This EventHandler genserver handle and run all the listener events.
  """
  use GenServer
  use SwarmNamed

  alias ApplicationRunner.ApplicationServices
  alias ApplicationRunner.Environment
  alias ApplicationRunner.Environment.TokenAgent
  alias ApplicationRunner.Guardian.AppGuardian
  alias ApplicationRunner.Session

  require Logger

  #########
  ## API ##
  #########

  @doc """
    Send async call to application,
    the call will run listeners with the given `action` `props` `event`
  """
  def send_env_event(env_id, action, props, event) do
    uuid = Ecto.UUID.generate()

    GenServer.call(
      get_full_name({:env, env_id}),
      {:send_event, action, props, event, env_id, uuid},
      Application.fetch_env!(:application_runner, :listeners_timeout)
    )
  end

  def send_session_event(session_id, action, props, event) do
    uuid = Ecto.UUID.generate()

    GenServer.call(
      get_full_name({:session, session_id}),
      {:send_event, action, props, event, session_id, uuid},
      Application.fetch_env!(:application_runner, :listeners_timeout)
    )
  end

  def send_client_event(session_id, code, event) do
    with {:ok, listener} <- Session.ListenersCache.fetch_listener(session_id, code),
         {:ok, action} <- Map.fetch(listener, "action"),
         props <- Map.get(listener, "props", %{}) do
      send_session_event(session_id, action, props, event)
    end
  end

  ###############
  ## Callbacks ##
  ###############

  def start_link(opts) do
    Logger.notice("Start #{__MODULE__}")
    Logger.debug("#{__MODULE__} start_link with opts #{inspect(opts)}")

    mode = Keyword.fetch!(opts, :mode)
    id = Keyword.fetch!(opts, :id)

    GenServer.start_link(__MODULE__, %{id: id, mode: mode}, name: get_full_name({mode, id}))
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call(
        {:send_event, "@lenra:" <> action, props, event, uuid, session_id},
        _from,
        state
      ) do
    Logger.debug(
      "#{__MODULE__} handle_call for @lenra action: #{inspect(action)} with props #{inspect(props)} and event #{inspect(event)}"
    )

    case action do
      "navTo" ->
        ApplicationRunner.RoutesChannel.get_name(session_id)
        |> Swarm.send({:send, :navTo, props})
    end

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(
        {:send_event, action, props, event, _id, uuid},
        _from,
        %{mode: mode, id: id} = state
      ) do
    Logger.debug(
      "#{__MODULE__} handle_call for action: #{inspect(action)} with props #{inspect(props)} and event #{inspect(event)}"
    )

    %{function_name: function_name, token: token} = get_metadata(mode, id) |> create_token(uuid)

    res = ApplicationServices.run_listener(function_name, action, props, event, token)

    {:reply, res, state}
  after
    %{env_id: env_id} = get_metadata(mode, id)

    TokenAgent.revoke_token(env_id, uuid)
  end

  defp create_token(%{function_name: function_name, user_id: user_id, env_id: env_id}, uuid) do
    {:ok, token, _claims} =
      AppGuardian.encode_and_sign(uuid, %{type: "session", env_id: env_id, user_id: user_id})

    TokenAgent.add_token(env_id, uuid, token)

    %{function_name: function_name, token: token, uuid: uuid, env_id: env_id}
  end

  defp create_token(%{function_name: function_name, env_id: env_id}, uuid) do
    {:ok, token, _claims} = AppGuardian.encode_and_sign(uuid, %{type: "env", env_id: env_id})

    TokenAgent.add_token(env_id, uuid, token)

    %{function_name: function_name, token: token, uuid: uuid, env_id: env_id}
  end

  defp get_metadata(:session, session_id) do
    Session.MetadataAgent.get_metadata(session_id)
  end

  defp get_metadata(:env, env_id) do
    Environment.MetadataAgent.get_metadata(env_id)
  end
end
