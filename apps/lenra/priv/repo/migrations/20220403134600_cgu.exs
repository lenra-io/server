defmodule Lenra.Repo.Migrations.Cgu do
  use Ecto.Migration

  def change do
    create table(:cgu) do
      add(:link, :string, null: false)
      add(:hash, :string, null: false)
      add(:version, :string, null: false)
      timestamps()
    end
  end
end
