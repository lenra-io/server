defmodule Lenra.Repo.Migrations.Permissions do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:new_role, :string, default: "unverified_user", null: false)
    end

    execute(&migrate_up/0, &migrate_down/0)

    alter table(:users) do
      remove(:role, :integer, default: 1)
    end

    rename(table(:users), :new_role, to: :role)
  end

  def migrate_up do
    repo().query!("
    UPDATE users as u
    SET new_role =
      CASE u.role
        WHEN 64 THEN 'admin'
        WHEN 2 THEN 'user'
        WHEN 1 THEN 'unverified_user'
      END
    ")
  end

  def migrate_down do
    repo().query!("""
    UPDATE users as u
    SET role =
      CASE u.new_role
        WHEN 'admin'THEN 64
        WHEN 'dev' THEN 4
        WHEN 'user' THEN 2
        WHEN 'unverified_user' THEN 1
      END
    """)
  end
end
