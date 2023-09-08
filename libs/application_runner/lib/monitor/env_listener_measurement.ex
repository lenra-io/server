defmodule ApplicationRunner.Monitor.EnvListenerMeasurement do
  @moduledoc """
    ApplicationRunner.Monitor.EnvListenerMeasurement is a ecto schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias ApplicationRunner.Contract.Environment

  @primary_key {:uuid, Ecto.UUID, autogenerate: true}
  schema "env_listener_measurement" do
    belongs_to(:environment, Environment)

    field(:start_time, :utc_datetime)
    field(:end_time, :utc_datetime)

    field(:duration, :integer)

    timestamps()
  end

  def changeset(listener_measurement, params \\ %{}) do
    listener_measurement
    |> cast(params, [:start_time, :end_time, :duration])
    |> validate_required([:start_time, :environment_id])
    |> foreign_key_constraint(:environment_id)
  end

  def new(environment_id, params \\ %{}) do
    %__MODULE__{environment_id: environment_id}
    |> __MODULE__.changeset(params)
  end

  def update(listener_measurement, params) do
    listener_measurement
    |> changeset(params)
  end
end
