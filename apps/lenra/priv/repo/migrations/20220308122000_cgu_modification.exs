defmodule Lenra.Repo.Migrations.UserAcceptCguVersion do
  use Ecto.Migration

  def change do
    create(unique_index(:cgu, [:link]))
    create(unique_index(:cgu, [:hash]))
    create(unique_index(:cgu, [:version]))
  end
end
