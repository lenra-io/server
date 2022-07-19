defmodule Lenra.Repo.Migrations.RemoveMonitoring do
  use Ecto.Migration

  def change do
    drop(table(:socket_app_measurements))

    drop(table(:docker_run_measurements))

    drop(table(:openfaas_runaction_measurements))

    drop(table(:action_logs))

    drop(table(:app_user_session))
  end
end
