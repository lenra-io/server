defmodule Lenra.Repo.Migrations.Codes do
  use Ecto.Migration

  def change do
    create table(:registration_codes) do
      add(:user_id, references(:users))
      add(:code, :string, null: false)
      timestamps()
    end

    unique_index(:registration_codes, [:user_id, :code])

    create table(:guardian_tokens, primary_key: false) do
      add(:jti, :string, primary_key: true)
      add(:aud, :string, primary_key: true)
      add(:typ, :string)
      add(:iss, :string)
      add(:sub, :string)
      add(:exp, :bigint)
      add(:jwt, :text)
      add(:claims, :map)
      timestamps()
    end
  end
end
