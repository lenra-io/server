defmodule Lenra.Monitor.ApplicationDeploymentMeasurement do
  @moduledoc """
    Lenra.Monitor.ApplicationDeploymentMeasurement is a ecto schema to store measurements of applications deployment.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.Apps.App

  schema "session_measurement" do
    belongs_to(:application, App)

    field(:start_time, :utc_datetime)
    field(:end_time, :utc_datetime)

    field(:duration, :integer)

    timestamps()
  end

  def changeset(application_deployment_measurement, params \\ %{}) do
    application_deployment_measurement
    |> cast(params, [:start_time, :end_time, :duration])
    |> validate_required([:start_time, :application_id])
    |> foreign_key_constraint(:application_id)
  end

  def new(application_id, params \\ %{}) do
    %__MODULE__{application_id: application_id}
    |> __MODULE__.changeset(params)
  end

  def update(application_deployment_measurement, params) do
    application_deployment_measurement
    |> changeset(params)
  end
end
