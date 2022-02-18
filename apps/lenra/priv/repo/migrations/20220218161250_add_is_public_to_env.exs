defmodule Lenra.Repo.Migrations.AddIsPublicToEnv do
  use Ecto.Migration

  def change do
    alter table(:environments) do
        add(:is_public, :boolean, default: false, null: false)
    end
  end
end
