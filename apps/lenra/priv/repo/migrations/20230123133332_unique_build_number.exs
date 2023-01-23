defmodule Lenra.Repo.Migrations.UniqueBuildNumber do
  use Ecto.Migration

  def change do
    create(unique_index(:builds, [:build_number, :application_id]))
  end
end
