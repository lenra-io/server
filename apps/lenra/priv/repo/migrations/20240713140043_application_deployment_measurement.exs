defmodule Lenra.Repo.Migrations.ApplicationDeploymentMeasurement do
  use Ecto.Migration

  def change do
    create table(:application_deployment_measurement) do
      add(:user_id, references(:users), null: false)
      add(:build_id, references(:builds), null: false)

      add(:start_time, :timestamp, null: false)
      add(:end_time, :timestamp)

      add(:duration, :integer)

      timestamps()
    end
  end
end
