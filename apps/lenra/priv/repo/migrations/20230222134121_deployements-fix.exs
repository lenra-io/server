defmodule :"Elixir.Lenra.Repo.Migrations.Deployements-fix" do
  use Ecto.Migration

  def change do
    execute("UPDATE deployments SET status = 'failure'")
  end
end
