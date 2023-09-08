defmodule ApplicationRunner.Session.ChangeEventManager do
  @moduledoc """
    This module is responsible to broadcast the mongo change event to all the QueryServer.
    It receive the mongo change event from the Environment.ChangeStream server.
  """
  use GenServer
  use SwarmNamed

  alias ApplicationRunner.Environment.QueryServer
  alias ApplicationRunner.Session.RouteServer

  require Logger

  def start_link(opts) do
    Logger.info("Start #{__MODULE__}")
    Logger.debug("#{__MODULE__} start_link with opts #{inspect(opts)}")
    session_id = Keyword.fetch!(opts, :session_id)
    env_id = Keyword.fetch!(opts, :env_id)
    mode = Keyword.fetch!(opts, :mode)
    route = Keyword.fetch!(opts, :route)

    with {:ok, pid} <-
           GenServer.start_link(__MODULE__, opts, name: get_full_name({session_id, mode, route})) do
      Swarm.join(get_group(env_id), pid)
      {:ok, pid}
    end
  end

  def get_group(env_id) do
    {__MODULE__, env_id}
  end

  def init(opts) do
    Logger.debug("#{__MODULE__} init with opts #{inspect(opts)}")

    session_id = Keyword.fetch!(opts, :session_id)
    mode = Keyword.fetch!(opts, :mode)
    route = Keyword.fetch!(opts, :route)

    {:ok, %{session_id: session_id, mode: mode, route: route}}
  end

  def handle_info(
        {:mongo_event, doc},
        %{session_id: session_id, mode: mode, route: route} = state
      ) do
    Logger.debug("#{__MODULE__} handle_info :mongo_event with state #{inspect(state)}")

    session_id
    |> QueryServer.group_name()
    |> Swarm.multi_call({:mongo_event, doc})
    |> Enum.reduce_while(
      :ok,
      fn
        :ok, _acc -> {:cont, :ok}
        err, _acc -> {:halt, {:error, err}}
      end
    )
    |> case do
      :ok ->
        GenServer.cast(RouteServer.get_full_name({session_id, mode, route}), :rebuild)

      {:error, err} ->
        GenServer.cast(RouteServer.get_full_name({session_id, mode, route}), {:data_error, err})
    end

    {:noreply, state}
  end
end
