defmodule Lenra.Repo.Migrations.UserAcceptCguVersion do
  use Ecto.Migration

  def change do
    create table(:user_accept_cgu_version, primary_key: false) do
      add(:user_id, references(:users, on_delete: :delete_all), primary_key: true)
      add(:cgu_id, references(:cgu, on_delete: :delete_all), primary_key: true)
      timestamps()
    end

    create(index(:user_accept_cgu_version, [:user_id]))
    create(index(:user_accept_cgu_version, [:cgu_id]))

    create(unique_index(:user_accept_cgu_version, [:user_id, :cgu_id], name: :user_id_cgu_id_unique_index))
  end
end
