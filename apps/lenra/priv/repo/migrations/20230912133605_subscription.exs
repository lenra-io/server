defmodule Lenra.Repo.Migrations.Subscription do
  use Ecto.Migration

  def change do
    create table(:subscriptions) do
      add(:start_date, :date)
      add(:end_date, :date)
      add(:application_id, :integer)

      timestamps()
    end
  end
end
