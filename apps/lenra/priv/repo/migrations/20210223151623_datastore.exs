defmodule Lenra.Repo.Migrations.Datastore do
  use Ecto.Migration

  def change do
    create table(:datastores) do
      add(:user_id, references(:users))
      add(:application_id, references(:applications))
      add(:data, :map)
      timestamps()
    end

    create(unique_index(:datastores, [:user_id, :application_id], name: :datastores_user_id_application_id_index))
  end
end
