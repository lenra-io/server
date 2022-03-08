defmodule Lenra.Repo.Migrations.UserAcceptCguVersion do
  use Ecto.Migration

  def change do
    drop(index(:user_accept_cgu_versions, [:user_id]))
    drop(index(:user_accept_cgu_versions, [:cgu_id]))
  end
end
