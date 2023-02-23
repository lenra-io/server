defmodule Lenra.Repo.Migrations.DeploymentsFix do
  use Ecto.Migration

  def change do
    execute("UPDATE deployments SET status = 'failure'")
  end
end
