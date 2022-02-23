defmodule Lenra.Repo.Migrations.TimestampsUtc do
  use Ecto.Migration

  def change do
    [
      "registration_codes",
      "guardian_tokens",
      "datastores",
      "deployments",
      "application_main_environment",
      "environments",
      "builds",
      "users",
      "passwords",
      "applications",
      "password_codes",
      "dev_codes",
      "app_user_session",
      "action_logs",
      "docker_run_measurements",
      "openfaas_runaction_measurements",
      "socket_app_measurements",
      "users_environments_access"
    ]
    |> Enum.each(fn table_name ->
      alter table(table_name) do
        modify(:inserted_at, :utc_datetime, from: :naive_datetime)
        modify(:updated_at, :utc_datetime, from: :naive_datetime)
      end
    end)
  end
end
