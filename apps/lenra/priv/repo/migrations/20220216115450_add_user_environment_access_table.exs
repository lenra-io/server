defmodule Lenra.Repo.Migrations.AddUserEnvironmentAccessTable do
  use Ecto.Migration

  def change do
    create table(:users_environments_access, primary_key: false) do
      add(:user_id, references(:users, on_delete: :delete_all), primary_key: true)
      add(:environment_id, references(:environments, on_delete: :delete_all), primary_key: true)
      timestamps()
    end

    create(index(:users_environments_access, [:user_id]))
    create(index(:users_environments_access, [:environment_id]))

    create(
      unique_index(:users_environments_access, [:user_id, :environment_id], name: :user_id_environment_id_unique_index)
    )
  end
end
