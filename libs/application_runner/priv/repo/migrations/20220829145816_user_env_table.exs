defmodule ApplicationRunner.Repo.Migrations.UserEnvTable do
  use Ecto.Migration

  def change do
    create table(:mongo_user_link, primary_key: false) do
      add(:mongo_user_id, :uuid, primary_key: true, null: false)
      add(:environment_id, references(:environments), null: false)
      add(:user_id, references(:users), null: false)
      timestamps()
    end

    create(unique_index(:mongo_user_link, [:user_id, :environment_id], name: :mongo_user_link_user_id_environment_id))
  end
end
