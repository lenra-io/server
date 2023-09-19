defmodule ApplicationRunner.Repo.Migrations.ActionToListener do
  use Ecto.Migration

  def change do
    rename(table("webhooks"), :action, to: :listener)
    rename(table("crons"), :listener_name, to: :listener)
  end
end
