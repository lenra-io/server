defmodule Lenra.SocketAppMeasurement do
  @moduledoc """
    The client's applications measurements schema.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Lenra.{AppUserSession, SocketAppMeasurement}

  schema "socket_app_measurements" do
    field(:duration, :integer)
    belongs_to(:app_user_session, AppUserSession, foreign_key: :app_user_session_uuid, type: :binary_id)
    timestamps()
  end

  def changeset(measurement, params \\ %{}) do
    measurement
    |> cast(params, [:duration])
    |> validate_required([:app_user_session_uuid, :duration])
    |> foreign_key_constraint(:app_user_session_uuid)
  end

  def new(params) do
    %SocketAppMeasurement{app_user_session_uuid: params.app_user_session_uuid}
    |> SocketAppMeasurement.changeset(params)
  end
end
