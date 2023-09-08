defmodule ApplicationRunner.Repo.Migrations.Webhooks do
  use Ecto.Migration

  def change do
    create table(:webhooks) do
      add(:uuid, :uuid, primary_key: true)
      add(:environment_id, references(:environments), null: false)
      add(:action, :string, null: false)
      add(:props, :map)

      timestamps()
    end
  end
end
