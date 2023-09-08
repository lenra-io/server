defmodule ApplicationRunner.Repo.Migrations.Data do
  use Ecto.Migration

  def change do

    create table(:environments) do
      timestamps()
    end

    create table(:users) do
      add(:email, :string, null: false, default: "test@lenra.io")
      timestamps()
    end
  end
end
