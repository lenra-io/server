defmodule Lenra.OpenfaasRunActionMeasurement do
  @moduledoc """
    The openfaas measurements schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{ActionLogs, OpenfaasRunActionMeasurement}

  schema "openfaas_runaction_measurements" do
    field(:duration, :integer)
    belongs_to(:action_logs, ActionLogs, foreign_key: :action_logs_uuid, type: :binary_id)

    timestamps()
  end

  def changeset(measurement, params \\ %{}) do
    measurement
    |> cast(params, [:duration])
    |> validate_required([:action_logs_uuid, :duration])
    |> foreign_key_constraint(:action_logs_uuid)
  end

  def new(params) do
    %OpenfaasRunActionMeasurement{action_logs_uuid: params.action_logs_uuid}
    |> OpenfaasRunActionMeasurement.changeset(params)
  end
end
