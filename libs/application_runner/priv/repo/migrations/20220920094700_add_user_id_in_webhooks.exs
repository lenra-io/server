defmodule ApplicationRunner.Repo.Migrations.AddUserIdInWebhooks do
  use Ecto.Migration

  def change do
    alter table(:webhooks) do
      add(:user_id, references(:users))
    end
  end
end
