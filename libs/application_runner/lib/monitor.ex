defmodule ApplicationRunner.Monitor do
  @moduledoc """
  This module is monitoring requests at different places
  ApplicationRunner's monitor executes the following events:
  * `[:ApplicationRunner, :app_session, :start]` - Executed on socket open.
    #### Measurements
      * start_time.
    #### Metadata
      * `:user_id` - The id of the user who executed the function.
      * `:env_id` - The name of the application from which the function was executed.
  * `[:ApplicationRunner, :app_session, :stop]` - Executed after socket closed.
    #### Measurements
      * end_time.
      * `:duration` - The time took by the openfaas function in `:native` unit of time.
  """
  import Ecto.Query, only: [from: 2]

  alias ApplicationRunner.Monitor.{
    EnvListenerMeasurement,
    SessionListenerMeasurement,
    SessionMeasurement
  }

  alias ApplicationRunner.Errors.AlertAgent

  @repo Application.compile_env(:application_runner, :repo)

  def setup do
    events = [
      [:application_runner, :app_session, :start],
      [:application_runner, :app_session, :stop],
      [:application_runner, :app_listener, :start],
      [:application_runner, :app_listener, :stop],
      [:application_runner, :alert, :event]
    ]

    :telemetry.attach_many(
      "application_runner.monitor",
      events,
      &ApplicationRunner.Monitor.handle_event/4,
      nil
    )
  end

  def handle_event([:application_runner, :app_session, :start], measurements, metadata, _config) do
    session_id = Map.get(metadata, :session_id)
    env_id = Map.get(metadata, :env_id)
    user_id = Map.get(metadata, :user_id)

    @repo.insert(SessionMeasurement.new(session_id, env_id, user_id, measurements))
  end

  def handle_event([:application_runner, :app_session, :stop], measurements, metadata, _config) do
    session_id = Map.get(metadata, :session_id)

    @repo.get_by!(SessionMeasurement, uuid: session_id)
    |> SessionMeasurement.update(measurements)
    |> @repo.update()
  end

  def handle_event([:application_runner, :app_listener, :start], measurements, metadata, _config) do
    Map.get(metadata, "type")
    |> case do
      "session" ->
        session_id = Map.get(metadata, "session_id")
        @repo.insert(SessionListenerMeasurement.new(session_id, measurements))

      "env" ->
        env_id = Map.get(metadata, "env_id")
        @repo.insert(EnvListenerMeasurement.new(env_id, measurements))
    end
  end

  def handle_event([:application_runner, :app_listener, :stop], measurements, metadata, _config) do
    Map.get(metadata, "type")
    |> case do
      "session" ->
        session_id = Map.get(metadata, "session_id")

        @repo.one!(
          from(sm in SessionListenerMeasurement,
            where: sm.session_measurement_uuid == ^session_id,
            order_by: [desc: sm.inserted_at],
            limit: 1
          )
        )
        |> SessionListenerMeasurement.update(measurements)
        |> @repo.update()

      "env" ->
        env_id = Map.get(metadata, "env_id")

        @repo.one(
          from(em in EnvListenerMeasurement,
            where: em.environment_id == ^env_id,
            order_by: [desc: em.inserted_at],
            limit: 1
          )
        )

        @repo.one!(
          from(em in EnvListenerMeasurement,
            where: em.environment_id == ^env_id,
            order_by: [desc: em.inserted_at],
            limit: 1
          )
        )
        |> EnvListenerMeasurement.update(measurements)
        |> @repo.update()
    end
  end

  def handle_event([:application_runner, :alert, :event], event, _metadata, _config) do
    case Swarm.whereis_name(event) do
      :undefined -> AlertAgent.start_link(event)
      pid -> AlertAgent.send_alert(pid, event)
    end
  end
end
