defmodule ApplicationRunner.Environment.QueryServer do
  @moduledoc """
    This module take care of updating a data to sync with the database.
    - It get the initial data from the mongo db using coll/query.
    - It wait for the Session Change Event and update the data accordingly
    - It use QueryParser to check if the new data actually match the query.
    - If the data is updated, it notify the view group using Swarm.publish
  """
  use GenServer
  use SwarmNamed

  alias ApplicationRunner.Environment.{MongoInstance, ViewServer}
  alias ApplicationRunner.MongoStorage
  alias LenraCommon.Errors.DevError
  alias QueryParser.Exec

  require Logger

  def start_link(opts) do
    Logger.debug("#{__MODULE__} start_link with #{inspect(opts)}")

    with {:ok, coll} <- Keyword.fetch(opts, :coll),
         {:ok, env_id} <- Keyword.fetch(opts, :env_id),
         {:ok, _query_transformed} <- Keyword.fetch(opts, :query_transformed),
         {:ok, query_parsed} <- Keyword.fetch(opts, :query_parsed) do
      GenServer.start_link(
        __MODULE__,
        opts,
        name: get_full_name({env_id, coll, query_parsed})
      )
    else
      :error ->
        raise DevError.exception(message: "QueryServer need a coll, a query_transformed, a query_parsed and an env_id")

      {:error, reason} ->
        {:error, reason}
    end
  end

  def group_name(session_id) do
    {__MODULE__, session_id}
  end

  def join_group(pid, session_id) do
    group = group_name(session_id)
    Swarm.join(group, pid)
  end

  def get_data(env_id, coll, query_parsed, projection, options) do
    GenServer.call(get_full_name({env_id, coll, query_parsed}), {:get_data, projection})
  end

  def add_projection(env_id, coll, query_parsed, projection) do
    GenServer.call(get_full_name({env_id, coll, query_parsed}), {:add_projection, projection})
  end

  # TODO: Figure out a way to fix the warning thrown by Parser...
  @dialyzer {:no_match, init: 1}

  def init(opts) do
    Logger.debug("#{__MODULE__} init with #{inspect(opts)}")

    with {:ok, env_id} <- Keyword.fetch(opts, :env_id),
         {:ok, coll} <- Keyword.fetch(opts, :coll),
         {:ok, query_transformed} <- Keyword.fetch(opts, :query_transformed),
         {:ok, query_parsed} <- Keyword.fetch(opts, :query_parsed),
         {:ok, projection} <- Keyword.fetch(opts, :projection),
         {:ok, options} <- Keyword.fetch(opts, :options),
         {:ok, data} <- fetch_initial_data(env_id, coll, query_transformed, projection, options) do
      projection_data =
        if projection != %{} do
          %{projection => projection_data(data, projection)}
        else
          %{}
        end

      {:ok,
       %{
         data: data,
         map_data: to_map_data(data),
         env_id: env_id,
         query_parsed: query_parsed,
         coll: coll,
         latest_timestamp: Mongo.timestamp(DateTime.utc_now()),
         done_ids: MapSet.new(),
         w_pids: MapSet.new(),
         projection_data: projection_data,
         options: options
       }}
    else
      :error ->
        raise DevError.exception("Missing data in opts (#{inspect(opts)}")

      {:error, err} ->
        {:stop, err}
    end
  end

  def get_data(env_id, coll, query_parsed) do
    GenServer.call(get_full_name({env_id, coll, query_parsed}), :get_data)
  end

  @doc """
    Start monitoring the given ViewServer
  """
  def monitor(qs_pid, w_pid) do
    Logger.debug("#{__MODULE__} monitor with #{inspect({qs_pid, w_pid})}")

    GenServer.call(qs_pid, {:monitor, w_pid})
  end

  defp to_map_data(data) do
    Logger.debug("#{__MODULE__} to_map_data with data: #{inspect(data)}")

    Map.new(data, fn d -> {Map.get(d, "_id"), d} end)
  end

  defp from_map_data(map_data) do
    Logger.debug("#{__MODULE__} from_map_data with data: #{inspect(map_data)}")

    Map.values(map_data)
  end

  defp fetch_initial_data(_env_id, coll, query_transformed, projection, options)
       when is_nil(coll) or is_nil(query_transformed) do
    Logger.debug("#{__MODULE__} fetch_initial_data with nil query")

    {:ok, []}
  end

  defp fetch_initial_data(env_id, coll, query_transformed, projection, options) do
    Logger.debug("#{__MODULE__} fetch_initial_data with data: #{inspect([env_id, coll, query_transformed])}")

    mongo_opts =
      Keyword.merge(
        # [projection: projection],
        [],
        Enum.map(options, fn {k, v} -> {String.to_atom(k), v} end)
      )

    MongoInstance.run_mongo_task(env_id, MongoStorage, :filter_docs, [
      env_id,
      coll,
      query_transformed,
      mongo_opts
    ])
  end

  defp projection_data(data, projection) do
    Enum.map(data, fn document ->
      Map.filter(document, fn {k, _v} -> Map.get(projection, k, false) end)
    end)
  end

  defp add_projection_data(projection_data, data, projection) do
    if projection != %{} do
      Map.put(projection_data, projection, projection_data(data, projection))
    end
  end

  defp projection_change?(projection_data, new_data, projection) do
    Map.get(projection_data, projection) == projection_data(new_data, projection)
  end

  def handle_call(
        {:add_projection, projection},
        _from,
        %{data: data, projection_data: projection_data} = state
      )
      when projection != %{} do
    new_state = Map.put(state, :projection_data, add_projection_data(projection_data, data, projection))

    {:reply, :ok, new_state}
  end

  def handle_call(
        {:add_projection, _projection},
        _from,
        state
      ) do
    {:reply, :ok, state}
  end

  def handle_call(
        {:mongo_event, _event},
        _from,
        %{coll: coll, query_parsed: query_parsed} = state
      )
      when is_nil(coll) or is_nil(query_parsed) do
    Logger.debug("#{__MODULE__} handle_call with :mongo_event with nil query")

    {:reply, :ok, state}
  end

  def handle_call(
        {:mongo_event, event},
        _from,
        state
      ) do
    Logger.debug("#{__MODULE__} handle_call with :mongo_event #{inspect(event)}")

    event_timestamp = get_in(event, ["clusterTime"])
    event_id = get_in(event, ["_id"])

    if event_handled?(event_id, event_timestamp, state) do
      # The event is already handled. Reply directly and ignore event.s
      {:reply, :ok, state}
    else
      # The event must be handled.
      handle_event(event, event_id, event_timestamp, state)
    end
  end

  def handle_call({:get_data, projection}, _from, state) do
    Logger.debug("#{__MODULE__} handle_call with :get_data with state: #{inspect(state)}")

    if projection != %{} do
      data = Map.get(state, :data)
      {:reply, projection_data(data, projection), state}
    else
      {:reply, Map.get(state, :data), state}
    end
  end

  def handle_call({:monitor, w_pid}, _from, state) do
    Logger.debug("#{__MODULE__} handle_call with :monitor for #{inspect(w_pid)}")

    Process.monitor(w_pid)
    new_w_ids = MapSet.put(state.w_pids, w_pid)
    {:reply, :ok, Map.put(state, :w_pids, new_w_ids)}
  end

  defp event_handled?(
         event_id,
         event_timestamp,
         %{
           latest_timestamp: latest_timestamp,
           done_ids: done_ids
         }
       ) do
    BSON.Timestamp.is_before(event_timestamp, latest_timestamp) or event_id in done_ids
  end

  defp handle_event(
         event,
         event_id,
         event_timestamp,
         %{
           latest_timestamp: latest_timestamp,
           done_ids: done_ids,
           query_parsed: query_parsed,
           data: data,
           map_data: map_data,
           coll: coll
         } = state
       ) do
    event_coll = get_in(event, ["ns", "coll"])
    op_type = get_in(event, ["operationType"])

    cond do
      event_coll == coll and op_type in ["insert", "update", "replace", "delete"] ->
        full_doc = get_in(event, ["fullDocument"])
        doc_id = get_in(event, ["documentKey", "_id"])

        {new_map_data, new_data, new_projection_data} =
          change_data(op_type, full_doc, doc_id, data, map_data, query_parsed, state)

        new_done_ids = get_new_done_ids(event_timestamp, latest_timestamp, event_id, done_ids)

        new_state =
          Map.merge(state, %{
            data: new_data,
            map_data: new_map_data,
            done_ids: new_done_ids,
            latest_timestamp: event_timestamp,
            new_projection_data: new_projection_data
          })

        {:reply, :ok, new_state}

      event_coll == coll and op_type in ["rename"] ->
        change_coll(op_type, event, state)

      event_coll == coll and op_type in ["drop"] ->
        stop(state)

      op_type in ["dropDatabase"] ->
        stop(state)

      true ->
        {:reply, :ok, state}
    end
  end

  defp get_new_done_ids(event_timestamp, latest_timestamp, event_id, done_ids) do
    if BSON.Timestamp.is_before(event_timestamp, latest_timestamp),
      do: MapSet.put(done_ids, event_id),
      else: MapSet.new([event_id])
  end

  defp change_coll(
         "rename",
         %{"ns" => %{"coll" => old_coll}, "to" => %{"coll" => new_coll}},
         %{query_parsed: query_parsed, env_id: env_id} = state
       ) do
    # Since the genserver name depend on coll, we change the name if the coll change.
    # Unregister old name
    Swarm.unregister_name(get_name({env_id, old_coll, query_parsed}))
    # Register new name
    Swarm.register_name(get_name({env_id, new_coll, query_parsed}), self())

    notify_coll_changed(new_coll, state)

    {:reply, :ok, Map.put(state, :coll, new_coll)}
  end

  defp change_coll(op_type, _event, _state) do
    raise DevError.exception("Could not handle #{op_type} event.")
  end

  defp stop(state) do
    {:stop, :normal, :ok, state}
  end

  defp stop_async(state) do
    {:stop, :normal, state}
  end

  defp change_data("insert", full_doc, doc_id, data, map_data, query_parsed, state) do
    parsed_query = filter_bson_id(query_parsed)

    if Exec.match?(full_doc, parsed_query) do
      new_map_data = Map.put(map_data, doc_id, full_doc)
      new_data = from_map_data(new_map_data)
      new_projection_data = notify_data_changed(new_data, state)
      {new_map_data, new_data, new_projection_data}
    else
      {map_data, data, Map.get(state, :projection)}
    end
  end

  defp change_data(op_type, full_doc, doc_id, data, map_data, query_parsed, state)
       when op_type in ["update", "replace"] do
    parsed_query = filter_bson_id(query_parsed)

    if Exec.match?(full_doc, parsed_query) do
      new_map_data = Map.put(map_data, doc_id, full_doc)
      new_data = from_map_data(new_map_data)

      new_projection_data = notify_data_changed(new_data, state)
      {new_map_data, new_data, new_projection_data}
    else
      old_length = Enum.count(map_data)
      new_map_data = Map.delete(map_data, doc_id)

      if old_length == Enum.count(new_map_data) do
        {map_data, data, Map.get(state, :projection_data)}
      else
        new_data = from_map_data(new_map_data)
        new_projection_data = notify_data_changed(new_data, state)
        {new_map_data, new_data, new_projection_data}
      end
    end
  end

  defp change_data("delete", _full_doc, doc_id, _data, map_data, _query_parsed, state) do
    new_map_data = Map.delete(map_data, doc_id)
    new_data = from_map_data(new_map_data)

    new_projection_data = notify_data_changed(new_data, state)

    {new_map_data, new_data, new_projection_data}
  end

  defp change_data(op_type, _full_doc, _doc_id, _data, _map_data, _query_parsed, state) do
    Logger.debug("Ingore event #{op_type}")
    {:reply, :ok, state}
  end

  @object_id_regex ~r/^ObjectId\(([[:xdigit:]]{24})\)$/

  defp filter_bson_id(map) when is_map(map) do
    Map.new(map, fn {key, value} ->
      {key, handle_filter_bson_id(value)}
    end)
  end

  defp filter_bson_id(map) when is_list(map) do
    Enum.map(map, fn value ->
      handle_filter_bson_id(value)
    end)
  end

  defp handle_filter_bson_id(value) do
    case value do
      str when is_bitstring(str) ->
        case Regex.run(@object_id_regex, str) do
          nil ->
            str

          [_, hex_id] ->
            BSON.ObjectId.decode!(hex_id)
        end

      sub_map when is_map(sub_map) ->
        filter_bson_id(sub_map)

      sub_list when is_list(sub_list) ->
        filter_bson_id(sub_list)

      value ->
        value
    end
  end

  defp notify_data_changed(
         new_data,
         %{
           env_id: env_id,
           query_parsed: query_parsed,
           coll: coll,
           projection_data: projection_data
         }
       ) do
    # Notify all ViewServer that projection changed
    new_projection_data =
      Enum.map(projection_data, fn {k, v} ->
        if projection_change?(projection_data, new_data, k) do
          {k, v}
        else
          # TODO: Check that the options are properly handled, we might want to get the options from the state
          group = ViewServer.group_name(env_id, coll, query_parsed, k, %{})
          Swarm.publish(group, {:data_changed, projection_data(new_data, k)})
          {k, projection_data(new_data, k)}
        end
      end)

    # Notify ViewServer with no projection.
    # TODO: Check that the options are properly handled, we might want to get the options from the state
    group = ViewServer.group_name(env_id, coll, query_parsed, %{}, %{})
    Swarm.publish(group, {:data_changed, new_data})

    new_projection_data
  end

  defp notify_coll_changed(
         new_coll,
         %{
           env_id: env_id,
           query_parsed: query_parsed,
           coll: old_coll,
           projection_data: projection_data
         }
       ) do
    Enum.each(Map.keys(projection_data), fn projection_key ->
      # TODO: Check that the options are properly handled, we might want to get the options from the state
      group = ViewServer.group_name(env_id, old_coll, query_parsed, projection_key, %{})
      Swarm.publish(group, {:coll_changed, new_coll})
    end)

    # TODO: Check that the options are properly handled, we might want to get the options from the state
    group = ViewServer.group_name(env_id, old_coll, query_parsed, %{}, %{})
    Swarm.publish(group, {:coll_changed, new_coll})
  end

  # If a ViewServer die, we receive a message here.
  # If there is no more monitored ViewServer, we stop this QueryServer.
  def handle_info({:DOWN, _ref, :process, w_pid, _reason}, state) do
    new_w_pids = MapSet.delete(state.w_pids, w_pid)

    if MapSet.size(new_w_pids) == 0 do
      stop_async(state)
    else
      {:noreply, Map.put(state, :w_pids, new_w_pids)}
    end
  end
end
