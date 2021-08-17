defmodule Lenra.Repo.Migrations.Lenra139AppVersion do
  use Ecto.Migration

  import Ecto.Query

  def change do
    create table(:builds) do
      add(:commit_hash, :string, null: false)
      add(:build_number, :integer, null: false)
      add(:status, :string, null: false)
      add(:creator_id, references(:users), null: false)
      add(:application_id, references(:applications), null: false)

      timestamps()
    end

    create(unique_index(:builds, [:id, :application_id]))
    create(constraint("builds", :status_enum, check: "status='pending' or status='success' or status='error'"))

    create table(:environments) do
      add(:name, :string, null: false)
      add(:is_ephemeral, :boolean, null: false)
      add(:application_id, references(:applications, on_delete: :delete_all), null: false)
      add(:creator_id, references(:users), null: false)
      add(:deployed_build_id, references(:builds))

      timestamps()
    end

    create(unique_index(:environments, [:id, :application_id]))
    create(unique_index(:environments, [:name, :application_id]))

    create table(:deployments) do
      add(:application_id, :integer, null: false)
      add(:environment_id, references(:environments, with: [application_id: :application_id]), null: false)
      add(:build_id, references(:builds, with: [application_id: :application_id]), null: false)
      add(:publisher_id, references(:users), null: false)

      timestamps()
    end

    create(unique_index(:deployments, [:environment_id, :build_id]))

    rename(table(:applications), :user_id, to: :creator_id)

    alter table(:applications) do
      remove(:env_process, :string, default: "node index.js")
      remove(:image, :string, default: "N/A")
      add(:service_name, :string)
    end

    execute(
      fn ->
        from(a in Lenra.LenraApplication, update: [set: [service_name: a.name]])
        |> repo().update_all([])
      end,
      fn -> nil end
    )

    alter table(:applications) do
      modify(:service_name, :string, null: false)
    end

    create table(:application_main_environment) do
      add(:environment_id, references(:environments, on_delete: :delete_all), null: false)
      add(:application_id, references(:applications, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:application_main_environment, [:application_id]))
  end
end
