defmodule :"Elixir.Lenra.Repo.Migrations.Deployment-change" do
  use Ecto.Migration

  def up do
    alter table(:deployments) do
      add(:status, :string, null: false)
    end

    execute("UPDATE deployments SET status = 'success'")

    rename(table(:environments), to: table(:environments_old))

    create table(:environments) do
      add(:name, :string, null: false)
      add(:is_ephemeral, :boolean, null: false)
      add(:is_public, :boolean, null: false)
      add(:application_id, references(:applications))
      add(:creator_id, references(:users))
      add(:deployment_id, references(:deployments))
      timestamps()
    end

    execute(
      "INSERT INTO environments(name, is_ephemeral, is_public, application_id, creator_id, deployment_id, inserted_at, updated_at)
      SELECT e.name, e.is_ephemeral, e.is_public, e.application_id, e.creator_id, d.id, e.inserted_at, e.updated_at FROM environments_old AS e
      JOIN deployments AS d ON d.build_id = e.deployed_build_id"
    )

    # drop(table(:environments_old))
  end

  def down do
    alter table(:deployments) do
      remove(:status, :string, null: false)
    end

    rename(table(:environments), to: table(:environments_old))

    create table(:environments) do
      add(:name, :string, null: false)
      add(:is_ephemeral, :boolean, null: false)
      add(:is_public, :boolean, null: false)
      add(:application_id, references(:applications))
      add(:creator_id, references(:users))
      add(:build_id, references(:builds))
    end

    execute(
      "INSERT INTO environments(name, is_ephemeral, is_public, application_id, creator_id, build_id, inserted_at, updated_at)
      SELECT e.name, e.is_ephemeral, e.is_public, e.application_id, e.creator_id, b.id, e.inserted_at, e.updated_at FROM environments_old AS e
      JOIN deployments AS d ON d.build_id = e.build_id
      JOIN builds AS b ON b.id = d.build_id"
    )

    drop(table(:environments_old))
  end
end
