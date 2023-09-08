defmodule ApplicationRunner.Repo.Migrations.SessionMonitor do
  use Ecto.Migration

  def change do
    create table(:session_measurement, primary_key: false) do
      add(:uuid, :uuid, primary_key: true)
      add(:user_id, references(:users), null: false)
      add(:environment_id, references(:environments), null: false)
      add(:start_time, :timestamp, null: false)
      add(:end_time, :timestamp)
      add(:duration, :integer)

      timestamps()
    end
  end
end
