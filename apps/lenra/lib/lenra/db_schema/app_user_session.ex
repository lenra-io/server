defmodule Lenra.AppUserSession do
  @moduledoc """
    The app session measurements schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{AppUserSession, User, SocketAppMeasurement, ActionLogs, LenraApplication}

  schema "app_user_session" do
    field(:uuid, :binary_id, primary_key: true)
    belongs_to(:user, User)
    belongs_to(:application, LenraApplication)
    field(:build_number, :integer)
    has_one(:socket_app_measurement, SocketAppMeasurement, foreign_key: :app_user_session_uuid)
    has_many(:action_logs, ActionLogs, foreign_key: :app_user_session_uuid)

    timestamps()
  end

  def changeset(app_user_session, params \\ %{}) do
    app_user_session
    |> cast(params, [:uuid, :user_id, :application_id, :build_number])
    |> validate_required([:uuid, :user_id, :application_id, :build_number])
    |> foreign_key_constraint(:user_id)
  end

  def new(params) do
    %AppUserSession{}
    |> AppUserSession.changeset(params)
  end
end
