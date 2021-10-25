defmodule Lenra.Repo.Migrations.UserData do
  use Ecto.Migration

  def change do
    create table(:dataspaces) do
      add(:application_id, references(:applications), null: false)
      add(:name, :string, null: false)
      add(:schema, :json, null: true)

      timestamps()
    end

    execute(
      "ALTER TABLE datastores rename column user_id TO owner_id",
      "ALTER TABLE datastores rename column owner_id TO user_id"
    )

    execute("TRUNCATE TABLE datastores;")

    drop(index(:datastores, [:user_id, :application_id], name: :datastores_user_id_application_id_index))

    alter table("datastores") do
      remove(:application_id, references(:applications))
      add(:dataspace_id, references(:dataspaces), null: false)
    end
  end
end
