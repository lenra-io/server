defmodule ApplicationRunner.Session.Supervisor do
  @moduledoc """
    This Supervisor is started by the SessionManager.
    It handle all the GenServer needed for the Session to work.
  """
  use Supervisor
  use SwarmNamed

  alias ApplicationRunner.Session

  require Logger

  def start_link(%Session.Metadata{} = session_metadata) do
    Logger.notice("Start #{__MODULE__}")
    Logger.debug("#{__MODULE__} start_link with session_metadata #{inspect(session_metadata)}")

    Supervisor.start_link(__MODULE__, session_metadata,
      name: get_full_name(session_metadata.session_id)
    )
  end

  @impl true
  def init(%Session.Metadata{} = sm) do
    children =
      [
        # TODO: add module once they done !
        {ApplicationRunner.Session.MetadataAgent, sm},
        {ApplicationRunner.EventHandler, mode: :session, id: sm.session_id},
        {Session.Events.OnSessionStart, session_id: sm.session_id}
      ] ++
        case sm.user_id do
          nil ->
            []

          _ ->
            [
              {Session.Events.OnUserFirstJoin,
               session_id: sm.session_id, env_id: sm.env_id, user_id: sm.user_id}
            ]
        end ++
        [
          {Session.ListenersCache, session_id: sm.session_id},
          {Session.RouteDynSup, session_id: sm.session_id}
        ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
