defmodule Lenra.Repo.Migrations.ModificationVersionCgu do
  use Ecto.Migration

  def change do
    alter table("cgu") do
      remove(:version)
      add(:version, :integer)
    end

    create(unique_index(:cgu, [:version]))
  end
end
