defmodule Lenra.Repo.Migrations.Password do
  use Ecto.Migration

  def change do
    create table(:passwords) do
      add(:user_id, references(:users), null: false)
      add(:password, :string, null: false)
      timestamps()
    end

    create(unique_index(:passwords, [:user_id, :password]))

    create table(:password_codes) do
      add(:user_id, references(:users), null: false)
      add(:code, :string, null: false)
      timestamps()
    end

    create(unique_index(:password_codes, [:user_id]))

    execute(
      "INSERT INTO passwords(user_id, password, inserted_at, updated_at) SELECT id, password, current_timestamp, current_timestamp FROM users;",
      "INSERT INTO users(password) SELECT passwords.password FROM passwords, users WHERE users.id=passwords.user_id;"
    )

    alter table(:users) do
      remove(:password, :string)
    end

    create(unique_index(:registration_codes, [:user_id]))
  end
end
