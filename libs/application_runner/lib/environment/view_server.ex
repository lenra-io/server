defmodule ApplicationRunner.Environment.ViewServer do
  @moduledoc """
    ApplicationRunner.Environment.View get a View and cache them
  """
  use GenServer
  use SwarmNamed

  alias ApplicationRunner.ApplicationServices
  alias ApplicationRunner.Environment.{QueryServer, ViewUid}

  require Logger

  def group_name(env_id, coll, query, projection) do
    {__MODULE__, env_id, coll, query, projection}
  end

  def join_group(pid, env_id, coll, query, projection) do
    group = group_name(env_id, coll, query, projection)
    Swarm.join(group, pid)
  end

  @spec fetch_view!(any, ViewUid.t()) :: map()
  def fetch_view!(env_id, view_uid) do
    filtered_view_uid = Map.filter(view_uid, fn {key, _value} -> key != :prefix_path end)

    GenServer.call(get_full_name({env_id, filtered_view_uid}), :fetch_view!)
  end

  def start_link(opts) do
    Logger.debug("#{__MODULE__} start_link with #{inspect(opts)}")

    env_id = Keyword.fetch!(opts, :env_id)
    view_uid = Keyword.fetch!(opts, :view_uid)

    filtered_view_uid = Map.filter(view_uid, fn {key, _value} -> key != :prefix_path end)

    GenServer.start_link(__MODULE__, opts, name: get_full_name({env_id, filtered_view_uid}))
  end

  @impl true
  def init(opts) do
    Logger.debug("#{__MODULE__} init with #{inspect(opts)}")

    function_name = Keyword.fetch!(opts, :function_name)
    env_id = Keyword.fetch!(opts, :env_id)
    %ViewUid{} = view_uid = Keyword.fetch!(opts, :view_uid)

    with data <-
           QueryServer.get_data(env_id, view_uid.coll, view_uid.query_parsed, view_uid.projection),
         {:ok, view} <-
           ApplicationServices.fetch_view(
             function_name,
             view_uid.name,
             data,
             view_uid.props,
             view_uid.context
           ) do
      state = %{
        view: view,
        function_name: function_name,
        view_uid: view_uid
      }

      {:ok, state}
    else
      {:error, error} ->
        {:stop, error}
    end
  end

  @doc """
    Receive notification from QueryServer when data changed and we need to refresh the view.
  """
  @impl true
  def handle_info({:data_changed, new_data}, state) do
    fna = Map.fetch!(state, :function_name)
    wuid = Map.fetch!(state, :view_uid)

    Logger.debug(
      "#{__MODULE__} handle_info for :data_changes with #{inspect(%{function_name: fna, view_uid: wuid})}"
    )

    case ApplicationServices.fetch_view(fna, wuid.name, new_data, wuid.props, wuid.context) do
      {:ok, view} ->
        {:noreply, Map.put(state, :view, view)}

      {:error, error} ->
        # TODO: send notification to channel
        Logger.critical(inspect(error))
    end
  end

  @impl true
  def handle_call(:fetch_view!, _from, state) do
    Logger.debug("#{__MODULE__} handle_info for :fetch_view!")

    {:reply, Map.fetch!(state, :view), state}
  end
end
