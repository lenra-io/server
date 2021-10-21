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

    alter table(:datastores) do
      remove(:user_id, references(:users))
    end
  end
end
