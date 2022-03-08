defmodule Lenra.Repo.Migrations.Cgu do
  use Ecto.Migration

  def change do
    create table(:cgu) do
      add(:link, :string, null: false)
      add(:hash, :string, null: false)
      add(:version, :string, null: false)
      timestamps()
    end

    create table(:user_accept_cgu_versions, primary_key: false) do
      add(:user_id, references(:users, on_delete: :delete_all), primary_key: true)
      add(:cgu_id, references(:cgu, on_delete: :delete_all), primary_key: true)
      timestamps()
    end

    create(index(:user_accept_cgu_versions, [:user_id]))
    create(index(:user_accept_cgu_versions, [:cgu_id]))

    create(unique_index(:user_accept_cgu_versions, [:user_id, :cgu_id], name: :user_id_cgu_id_unique_index))
  end
end
