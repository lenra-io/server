defmodule Lenra.Repo.Migrations.EnvScaleOption do
  use Ecto.Migration

  def change do
    create table(:environments_scale_options) do
      add(:environment_id, references(:environments, on_delete: :delete_all), null: false)
      add(:min, :integer)
      add(:max, :integer)

      timestamps()
    end

    create(unique_index(:environments_scale_options, [:environment_id]))
  end
end
