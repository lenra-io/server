defmodule Lenra.Repo.Migrations.UserData do
  use Ecto.Migration

  def change do
    # execute(
    #  "ALTER TABLE datastores rename column user_id TO owner_id",
    #  "ALTER TABLE datastores rename column owner_id TO user_id"
    # )

    execute("TRUNCATE TABLE datastores;")

    drop(index(:datastores, [:user_id, :application_id], name: :datastores_user_id_application_id_index))

    alter table("datastores") do
      remove(:user_id, references(:users))
      remove(:data, :map)
      remove(:application_id, references(:applications))
      add(:name, :string)
      add(:environment_id, references(:environments), null: false)
    end

    create table(:data) do
      add(:datastore_id, references(:datastores), null: false)
      add(:data, :map, null: false)

      timestamps()
    end

    create table(:data_references) do
      add(:refs_id, references(:data), null: false)
      add(:refBy_id, references(:data), null: false)

      timestamps()
    end
  end
end
