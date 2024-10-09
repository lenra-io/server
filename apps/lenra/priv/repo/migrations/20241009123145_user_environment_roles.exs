defmodule Lenra.Repo.Migrations.UserEnvironmentRoles do
  use Ecto.Migration

  def change do
    create table(:users_environments_roles) do
      add(:access_id, references(:users_environments_access, on_delete: :delete_all))
      add(:creator_id, references(:users))
      add(:role, :string)

      timestamps()
    end

    create(
      unique_index(:users_environments_roles, [:access_id, :role])
    )
  end
end
