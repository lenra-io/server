defmodule Lenra.Repo.Migrations.Application do
  use Ecto.Migration

  def change do
    create table(:applications) do
      add(:user_id, references(:users))
      add(:image, :string, null: false)
      add(:name, :string, null: false)
      add(:env_process, :string, null: false)
      add(:color, :string, null: false)
      add(:icon, :integer, null: false)
      timestamps()
    end

    create(unique_index(:applications, [:name]))
  end
end
