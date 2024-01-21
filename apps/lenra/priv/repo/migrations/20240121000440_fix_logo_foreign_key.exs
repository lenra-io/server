defmodule Lenra.Repo.Migrations.FixLogoForeignKey do
  use Ecto.Migration

  def change do
    drop(constraint(:logos, "logos_environment_id_fkey"))

    alter table(:logos) do
      modify(:environment_id, references(:environments, on_delete: :delete_all), null: true)
    end
  end
end
