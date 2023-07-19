defmodule Lenra.Repo.Migrations.OauthClient do
  use Ecto.Migration

  def change do
    create table(:oauth_clients) do
      add(:environment_id, references(:environments))
      add(:oauth_client_id, :string, null: false)
      timestamps()
    end

    create(unique_index(:oauth_clients, [:oauth_client_id]))
  end
end
