defmodule ApplicationRunner.Repo.Migrations.NullableSessionUser do
  use Ecto.Migration

  def change do
    drop(constraint(:session_measurement, "session_measurement_user_id_fkey"))

    alter table(:session_measurement) do
      modify(:user_id, references(:users), null: true)
    end
  end
end
