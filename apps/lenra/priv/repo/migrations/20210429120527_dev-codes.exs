defmodule :"Elixir.Lenra.Repo.Migrations.Dev-codes" do
  use Ecto.Migration

  def change do
    create table(:dev_codes) do
      add(:user_id, references(:users))
      add(:code, :uuid, null: false)
      timestamps()
    end

    create(unique_index(:dev_codes, [:code]))
    create(unique_index(:dev_codes, [:user_id]))
  end
end
