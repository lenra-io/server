defmodule Lenra.Repo.Migrations.UsersEnvironmentsAccessUpdate do
  use Ecto.Migration

  def change do
    drop(index(:users_environments_access, [:user_id]))
    drop(index(:users_environments_access, [:environment_id]))

    drop(
      unique_index(:users_environments_access, [:user_id, :environment_id], name: :user_id_environment_id_unique_index)
    )

    rename(table(:users_environments_access), to: table(:users_environments_access_old))

    create table(:users_environments_access, primary_key: false) do
      add(:uuid, :binary_id, primary_key: true)
      add(:user_id, references(:users, on_delete: :delete_all), null: true)
      add(:environment_id, references(:environments, on_delete: :delete_all))

      timestamps()
    end

    execute(
      "INSERT INTO users_environments_access(user_id, environment_id) SELECT old.user_id, old.environment_id FROM users_environments_access_old AS old"
    )

    drop(table(:users_environments_access_old))

    create(
      unique_index(:users_environments_access, [:user_id, :environment_id], name: :user_id_environment_id_unique_index)
    )
  end
end
