defmodule Lenra.Repo.Migrations.Cgus do
  use Ecto.Migration

  def change do
    create table(:cgus) do
      add(:link, :string, null: false)
      add(:version, :string, null: false)
      add(:hash, :string, null: false)
      timestamps()
    end
  end
end
