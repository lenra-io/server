defmodule Lenra.Repo.Migrations.Lenra170ClientAppMonitoring do
  use Ecto.Migration

  def change do
    create table(:client_app_measurements) do
      add(:user_id, references(:users), null: false)
      add(:application_name, :string, null: false)
      add(:duration, :bigint, null: false)

      timestamps()
    end

    execute(
      fn ->
        repo().query("COMMENT ON COLUMN client_app_measurements.duration IS 'This is the duration in nanoseconds'")
      end,
      fn ->
        nil
      end
    )
  end
end
