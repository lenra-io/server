defmodule Lenra.Repo.Migrations.OauthClient do
  use Ecto.Migration

  def change do
    create table(:oauth2_clients) do
      add(:environment_id, references(:environments))
      add(:oauth2_client_id, :string, null: false)
      timestamps()
    end

    create(unique_index(:oauth2_clients, [:oauth2_client_id]))
  end
end
