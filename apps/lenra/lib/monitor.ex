defmodule Lenra.Monitor do
  @moduledoc """
  This module is monitoring requests at different places

  Lenra's monitor executes the following events:

  * `[:lenra, :openfaas_action, :start]` - Executed before an openfaas action.

    #### Measurements

      * No need for any measurement.

    #### Metadata

      * No need for any metadata.

  * `[:lenra, :openfaas_action, :stop]` - Executed after an openfaas action.

    #### Measurements

      * `:duration` - The time took by the openfaas action in `:native` unit of time.

    #### Metadata

      * `:user_id` - The id of the user who executed the action.
      * `:application_name` - The name of the application from which the action was executed.

  """

  alias Lenra.{
    ActionLogsService,
    AppUserSessionService,
    DockerRunMeasurementServices,
    OpenfaasRunActionMeasurementServices,
    SocketAppMeasurementServices
  }

  def setup do
    events = [
      [:lenra, :openfaas_runaction, :stop],
      [:lenra, :action_logs, :event],
      [:lenra, :docker_run, :event],
      [:lenra, :app_user_session, :start],
      [:lenra, :app_user_session, :stop]
    ]

    :telemetry.attach_many("lenra.monitor", events, &Lenra.Monitor.handle_event/4, nil)
  end

  def handle_event([:lenra, :openfaas_runaction, :stop], measurements, metadata, _config) do
    OpenfaasRunActionMeasurementServices.create(%{
      action_logs_uuid: metadata.uuid,
      duration: System.convert_time_unit(measurements.duration, :native, :nanosecond)
    })
  end

  def handle_event([:lenra, :docker_run, :event], measurements, metadata, _config) do
    DockerRunMeasurementServices.create(%{
      action_logs_uuid: metadata.uuid,
      ui_duration: measurements.uiDuration,
      listeners_duration: measurements.listenersTime
    })
  end

  def handle_event([:lenra, :action_logs, :event], _measurements, metadata, _config) do
    ActionLogsService.create(%{
      uuid: metadata.uuid,
      app_user_session_uuid: metadata.app_user_session_uuid,
      action: metadata.action
    })
  end

  def handle_event([:lenra, :app_user_session, :start], _measurements, metadata, _config) do
    AppUserSessionService.create(metadata.user_id, %{
      uuid: metadata.app_user_session_uuid,
      service_name: metadata.service_name,
      build_number: metadata.build_number
    })
  end

  def handle_event([:lenra, :app_user_session, :stop], measurements, metadata, _config) do
    SocketAppMeasurementServices.create(%{
      app_user_session_uuid: metadata.app_user_session_uuid,
      duration: System.convert_time_unit(measurements.duration, :native, :nanosecond)
    })
  end

  def handle_event(_event, _measurements, _metadata, _config) do
  end
end
