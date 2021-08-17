defmodule :"Elixir.Lenra.Repo.Migrations.Gitlab-builder" do
  use Ecto.Migration

  def up do
    alter table(:applications) do
      add(:repository, :string)
    end

    alter table(:builds) do
      modify(:commit_hash, :string, null: true)
    end

    drop(constraint(:builds, :status_enum))
    create(constraint(:builds, :status_enum, check: "status='pending' or status='success' or status='failure'"))
  end

  def down do
    alter table(:applications) do
      remove(:repository)
    end

    drop(constraint(:builds, :status_enum))
    create(constraint(:builds, :status_enum, check: "status='pending' or status='success' or status='error'"))
  end
end
