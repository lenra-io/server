defmodule ApplicationRunner.Repo.Migrations.AddCronTable do
  use Ecto.Migration

  def change do
    create table(:crons) do
      add(:environment_id, references(:environments), null: false)
      add(:user_id, references(:users))
      add(:listener_name, :string, null: false)
      add(:cron_expression, :string, null: false)
      add(:props, :map)

      add(:should_run_missed_steps, :boolean, default: false)
      add(:last_run_date, :date)

      timestamps()
    end
  end
end
