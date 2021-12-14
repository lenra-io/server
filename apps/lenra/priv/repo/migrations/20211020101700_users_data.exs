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
      add(:name, :string)
    end

    create table(:datas) do
      add(:datastore_id, references(:datastores), null: false)
      add(:data, :map, null: false)

      timestamps()
    end

    create table(:refs) do
      add(:referencer_id, references(:datas), null: false)
      add(:referenced_id, references(:datas), null: false)

      timestamps()
    end
  end
end
