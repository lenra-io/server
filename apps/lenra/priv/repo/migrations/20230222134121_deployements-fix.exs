defmodule Lenra.Repo.Migrations.DeployementsFix do
  use Ecto.Migration

  def change do
    execute("UPDATE deployments SET status = 'failure'")
  end
end
