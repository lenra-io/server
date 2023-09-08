defmodule ApplicationRunner.Repo.Migrations.EditCronTable do
  use Ecto.Migration

  def change do
    alter table(:crons) do
      add :name, :string
      add :overlap, :boolean
      add :state, :string
      add :function_name, :string
      remove :last_run_date
    end

    rename table(:crons), :cron_expression, to: :schedule
  end
end
