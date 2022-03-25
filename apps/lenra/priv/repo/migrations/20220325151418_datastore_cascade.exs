defmodule Lenra.Repo.Migrations.DatastoreCascade do
  use Ecto.Migration

  def change do
    drop(constraint(:datastores, "datastores_environment_id_fkey"))

    alter table(:datastores) do
      modify(:environment_id, references(:environments, on_delete: :delete_all))
    end
  end
end
