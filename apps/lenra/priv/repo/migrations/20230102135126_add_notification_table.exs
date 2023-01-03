defmodule Lenra.Repo.Migrations.AddNotificationTable do
  use Ecto.Migration

  def change do
    create table(:notify_provider) do
      add(:user_id, references(:users), null: false)
      add(:device_id, :string, null: false)
      add(:endpoint, :string, null: false)
      add(:system, :string, null: false)
      timestamps()
    end

    create(unique_index(:notify_provider, [:device_id]))
  end
end
