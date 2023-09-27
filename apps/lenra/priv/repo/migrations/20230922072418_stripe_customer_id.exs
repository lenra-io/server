defmodule Lenra.Repo.Migrations.StripeCustomerId do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:stripe_id, :string, null: true)
    end
  end
end
