defmodule ApplicationRunner.Repo.Migrations.AddLastExecutionDateTableCron do
  use Ecto.Migration

  def change do
    create table(:quantum, primary_key: false) do
      add :id, :integer, primary_key: true, null: false
      add :last_execution_date, :naive_datetime
    end

    create constraint("quantum", :only_one_record, check: "id = 1")
  end
end
