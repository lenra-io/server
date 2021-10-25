defmodule Lenra.Repo.Migrations.UserData do
  use Ecto.Migration

  def change do
    create table(:datastore_users) do
      add(:user_id, references(:users), null: false)
      add(:datastores_id, references(:datastores), null: false)

      timestamps()
    end

    create(unique_index(:datastore_users, [:user_id, :datastores_id], name: :datastore_users_user_id_datastore_id))

    execute(
      "INSERT INTO datastore_users(user_id, datastores_id) SELECT datastores.user_id, datastores.id FROM datastores;",
      "INSERT INTO datastores(user_id) SELECT user_id FROM datastore_users WHERE datastore_users.datastores_id = datastores.id;"
    )

    execute(
      "ALTER TABLE datastores rename column user_id TO owner_id",
      "ALTER TABLE datastores rename column owner_id TO user_id"
    )

    drop(index(:datastores, [:user_id, :application_id], name: :datastores_user_id_application_id_index))
  end
end
