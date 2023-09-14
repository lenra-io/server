defmodule Lenra.Repo.Migrations.Subscription do
  use Ecto.Migration

  def change do
    create table(:subscriptions, primary_key: false) do
      add(:uuid, :uuid, primary_key: true)
      add(:start_date, :date)
      add(:end_date, :date)
      add(:application_id, :integer)

      timestamps()
    end
  end
end
