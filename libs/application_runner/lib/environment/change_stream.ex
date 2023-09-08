defmodule ApplicationRunner.Environment.ChangeStream do
  @moduledoc """
    This module listen from database change for the environment.
    It then broadcast the change to all the Session.ChangeEventManager

    It should never stop.
  """
  use GenServer
  use SwarmNamed

  alias ApplicationRunner.Environment.MongoInstance
  alias ApplicationRunner.Session.ChangeEventManager

  require Logger

  def start_link(opts) do
    Logger.debug("#{__MODULE__} start_link with #{inspect(opts)}")
    env_id = Keyword.fetch!(opts, :env_id)
    res = GenServer.start_link(__MODULE__, opts, name: get_full_name(env_id))
    Logger.debug("#{__MODULE__} start_link exit with #{inspect(res)}")
    res
  end

  def init(opts) do
    Logger.debug("#{__MODULE__} init with #{inspect(opts)}")

    env_id = Keyword.fetch!(opts, :env_id)
    Logger.info("start change stream for env: #{env_id}")

    state = %{env_id: env_id}

    Logger.debug("#{__MODULE__} init exit with #{inspect(state)}")

    {:ok, state, {:continue, :start_stream}}
  end

  def handle_continue(:start_stream, %{env_id: env_id} = state) do
    # With spawn_link, if the started process die, this genserver dies too.
    cs_pid = spawn_link(fn -> start_change_stream(env_id) end)
    new_state = Map.put(state, :cs_pid, cs_pid)
    {:noreply, new_state}
  end

  def handle_cast({:token_event, token}, state) do
    Logger.debug("New token : #{inspect(token)}")
    {:noreply, state}
  end

  def handle_cast({:mongo_event, doc}, %{env_id: env_id} = state) do
    Logger.debug(
      "#{__MODULE__} cast #{inspect({:mongo_event, doc})} for env #{env_id} : #{inspect(doc)}"
    )

    Swarm.publish(ChangeEventManager.get_group(env_id), {:mongo_event, doc})
    {:noreply, state}
  end

  defp start_change_stream(env_id) do
    mongo_name = MongoInstance.get_full_name(env_id)
    cs_name = get_full_name(env_id)

    Logger.debug(
      "#{__MODULE__}  start_change_stream for env #{env_id}, with mongo_name: #{inspect(mongo_name)}"
    )

    Mongo.watch_db(
      mongo_name,
      [],
      fn token ->
        GenServer.cast(cs_name, {:token_event, token})
      end,
      full_document: "updateLookup"
    )
    # This Enum.each loop forever. It lock the current process.
    |> Enum.each(fn doc ->
      GenServer.cast(cs_name, {:mongo_event, doc})
    end)
  end
end
