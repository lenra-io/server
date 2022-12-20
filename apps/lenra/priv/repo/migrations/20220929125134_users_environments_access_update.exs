defmodule Lenra.Repo.Migrations.UsersEnvironmentsAccessUpdate do
  use Ecto.Migration

  def change do
    drop(index(:users_environments_access, [:user_id]))
    drop(index(:users_environments_access, [:environment_id]))

    drop(
      unique_index(:users_environments_access, [:user_id, :environment_id], name: :user_id_environment_id_unique_index)
    )

    rename(table(:users_environments_access), to: table(:users_environments_access_old))

    create table(:users_environments_access) do
      add(:email, :string)
      add(:user_id, references(:users, on_delete: :delete_all), null: true)
      add(:environment_id, references(:environments, on_delete: :delete_all))

      timestamps()
    end

    execute(
      "INSERT INTO users_environments_access(user_id, environment_id, inserted_at, updated_at) SELECT old.user_id, old.environment_id, old.inserted_at, old.updated_at FROM users_environments_access_old AS old"
    )

    drop(table(:users_environments_access_old))

    create(
      unique_index(:users_environments_access, [:user_id, :environment_id], name: :user_id_environment_id_unique_index)
    )

    create(
      unique_index(:users_environments_access, [:email, :environment_id], name: :email_environment_id_unique_index)
    )
  end
end
