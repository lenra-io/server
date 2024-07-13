defmodule Lenra.Monitor do
  @moduledoc """
  This module is monitoring requests at different places
  Lenra's monitor executes the following events:
  * `[:lenra, :app_deployment, :start]` - Executed when the app's deployment is triggered.
    #### Measurements
      * start_time.
    #### Metadata
      * `:application_id` - The id of the deploying application.
      * `:build_id` - The id of the deploying build.
  * `[:lenra, :app_deployment, :stop]` - Executed when the `available_replicas` parameter is not 0 or null on OpenFaaS.
    #### Measurements
      * end_time.
      * `:duration` - The time took by the openfaas function in `:native` unit of time.
  """

  alias Lenra.Monitor.ApplicationDeploymentMeasurement
  alias Lenra.Repo

  def setup do
    events = [
      [:lenra, :app_deployment, :start],
      [:lenra, :app_deployment, :stop]
    ]

    :telemetry.attach_many(
      "lenra.monitor",
      events,
      &Lenra.Monitor.handle_event/4,
      nil
    )
  end

  def handle_event([:lenra, :app_deployment, :start], measurements, metadata, _config) do
    application_id = Map.get(metadata, :application_id)
    build_id = Map.get(metadata, :build_id)

    Repo.insert(ApplicationDeploymentMeasurement.new(application_id, build_id, measurements))
  end

  def handle_event([:lenra, :app_deployment, :stop], measurements, metadata, _config) do
    application_id = Map.get(metadata, :application_id)
    build_id = Map.get(metadata, :build_id)

    Repo.get_by!(ApplicationDeploymentMeasurement, %{application_id: application_id, build_id: build_id})
    |> ApplicationDeploymentMeasurement.update(measurements)
    |> Repo.update()
  end
end
