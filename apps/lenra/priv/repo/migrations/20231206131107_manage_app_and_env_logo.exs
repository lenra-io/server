defmodule Lenra.Repo.Migrations.ManageAppAndEnvLogo do
  use Ecto.Migration

  def change do
    create table(:images) do
      add(:creator_id, references(:users))
      add :data, :binary
      add :type, :string
      timestamps()
    end
    create table(:logos) do
      add(:application_id, references(:applications))
      add(:environment_id, references(:applications), null: true)
      add(:image_id, references(:images))
      timestamps()
    end

    create(unique_index(:logos, [:application_id, :environment_id], name: :logos_application_id_environment_id_index))
  end
end
