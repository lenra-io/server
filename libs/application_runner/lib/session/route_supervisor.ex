defmodule ApplicationRunner.Session.RouteSupervisor do
  @moduledoc """
    This Supervisor is started by the SessionManager.
    It handle all the GenServer needed for the Session to work.
  """
  use Supervisor
  use SwarmNamed

  alias ApplicationRunner.Session

  def start_link(opts) do
    session_id = Keyword.fetch!(opts, :session_id)
    mode = Keyword.fetch!(opts, :mode)
    route = Keyword.fetch!(opts, :route)

    Supervisor.start_link(__MODULE__, opts, name: get_full_name({session_id, mode, route}))
  end

  @impl true
  def init(opts) do
    env_id = Keyword.fetch!(opts, :env_id)
    session_id = Keyword.fetch!(opts, :session_id)
    mode = Keyword.fetch!(opts, :mode)
    route = Keyword.fetch!(opts, :route)

    children = [
      {Session.ChangeEventManager, env_id: env_id, session_id: session_id, mode: mode, route: route},
      {Session.RouteServer, session_id: session_id, mode: mode, route: route}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
