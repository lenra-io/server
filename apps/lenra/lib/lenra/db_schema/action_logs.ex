defmodule Lenra.ActionLogs do
  @moduledoc """
    The ActionLogs schema.
  """

  use Lenra.Schema
  import Ecto.Changeset

  alias Lenra.{
    ActionLogs,
    AppUserSession,
    DockerRunMeasurement,
    OpenfaasRunActionMeasurement
  }

  schema "action_logs" do
    field(:uuid, :binary_id, primary_key: true)
    field(:action, :string)
    belongs_to(:app_user_session, AppUserSession, foreign_key: :app_user_session_uuid, type: :binary_id)
    has_one(:openfaas_runaction_measurements, OpenfaasRunActionMeasurement, foreign_key: :action_logs_uuid)
    has_one(:docker_run_measurements, DockerRunMeasurement, foreign_key: :action_logs_uuid)

    timestamps()
  end

  def changeset(action, params \\ %{}) do
    action
    |> cast(params, [:uuid, :action])
    |> validate_required([:uuid, :app_user_session_uuid, :action])
    |> foreign_key_constraint(:app_user_session_uuid)
  end

  def new(params) do
    %ActionLogs{app_user_session_uuid: params.app_user_session_uuid}
    |> ActionLogs.changeset(params)
  end
end
