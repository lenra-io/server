defmodule Lenra.Repo.Migrations.UserData do
  use Ecto.Migration

  def change do
    create table(:applications_data) do
      add(:application_id, references(:applications), null: false)
      add(:json_data, :jsonb, null: false)

      timestamps()
    end

    create table(:applications_users_data) do
      add(:user_id, references(:users), null: false)
      add(:applications_data_id, references(:applications_data), null: false)

      timestamps()
    end

    create(
      unique_index(:applications_users_data, [:user_id, :applications_data_id],
        name: :app_users_data_user_id_app_data_id
      )
    )
  end
end
