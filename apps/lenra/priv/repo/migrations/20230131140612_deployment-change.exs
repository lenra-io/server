defmodule :"Elixir.Lenra.Repo.Migrations.Deployment-change" do
  use Ecto.Migration

  def up do
    alter table(:deployments) do
      add(:status, :string, null: true)
    end

    execute("UPDATE deployments SET status = 'failed'")

    alter table(:deployments) do
      modify(:status, :string, null: false)
    end

    alter table(:environments) do
      add(:deployment_id, references(:deployments))
    end

    execute("UPDATE environments AS e SET deployment_id =
      (SELECT d.id FROM deployments AS d WHERE d.build_id = e.deployed_build_id)")

    alter table(:environments) do
      remove(:deployed_build_id, references(:builds))
    end
  end

  def down do
    alter table(:deployments) do
      remove(:status, :string, null: false)
    end

    alter table(:environments) do
      add(:deployed_build_id, references(:builds))
    end

    execute("UPDATE environments AS e SET deployed_build_id = (
      SELECT b.id FROM builds as b
      JOIN deployments AS d ON d.id = e.deployment_id)")

    alter table(:environments) do
      remove(:deployment_id, references(:deployments))
    end
  end
end
