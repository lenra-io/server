defmodule Lenra.Repo.Migrations.AddEnvSecret do
  use Ecto.Migration

  def change do
    create table(:env_secrets) do
      add(:environment_id, references(:environments))
      add(:key, :string)
      add(:value, :string)
      add(:is_obfuscated, :boolean, default: true)
      timestamps()
    end

    create(unique_index(:env_secrets, [:environment_id, :key], name: :env_secrets_environment_id_key_index))
  end
end
