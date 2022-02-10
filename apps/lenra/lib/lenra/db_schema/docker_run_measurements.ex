defmodule Lenra.DockerRunMeasurement do
  @moduledoc """
    The openfaas measurements schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{ActionLogs, DockerRunMeasurement}

  schema "docker_run_measurements" do
    field(:ui_duration, :integer)
    field(:listeners_duration, :integer)
    belongs_to(:action_logs, ActionLogs, foreign_key: :action_logs_uuid, type: :binary_id)

    timestamps()
  end

  def changeset(measurement, params \\ %{}) do
    measurement
    |> cast(params, [:ui_duration, :listeners_duration, :action_logs_uuid])
    |> validate_required([:action_logs_uuid, :ui_duration, :listeners_duration])
    |> foreign_key_constraint(:action_logs_uuid)
  end

  def new(params) do
    DockerRunMeasurement.changeset(%DockerRunMeasurement{}, params)
  end
end
