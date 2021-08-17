defmodule Lenra.Repo.Migrations.Lenra168Monitoring do
  use Ecto.Migration

  def up do
    create table(:app_user_session) do
      add(:uuid, :uuid, primary_key: true)
      add(:application_id, references(:applications), null: false)
      add(:build_number, :integer, null: false)
      add(:user_id, references(:users), null: false)

      timestamps()
    end

    create(unique_index(:app_user_session, [:uuid]))

    create table(:action_logs) do
      add(:uuid, :uuid, primary_key: true)
      add(:app_user_session_uuid, references(:app_user_session, column: :uuid, type: :uuid), null: false)
      add(:action, :string, null: false)

      timestamps()
    end

    create(unique_index(:action_logs, [:uuid]))

    create table(:docker_run_measurements) do
      add(:action_logs_uuid, references(:action_logs, column: :uuid, type: :uuid), null: false)
      add(:ui_duration, :bigint, null: false)
      add(:listeners_duration, :bigint, null: false)

      timestamps()
    end

    execute("TRUNCATE TABLE openfaas_runaction_measurements;")

    alter table(:openfaas_runaction_measurements) do
      remove(:user_id, references(:users))
      remove(:application_name, :string)
      add(:action_logs_uuid, references(:action_logs, column: :uuid, type: :uuid), null: false)
    end

    create table(:socket_app_measurements) do
      add(:app_user_session_uuid, references(:app_user_session, column: :uuid, type: :uuid), null: false)
      add(:duration, :bigint, null: false)

      timestamps()
    end

    execute(
      fn ->
        repo().query(
          "COMMENT ON COLUMN docker_run_measurements.ui_duration IS 'This is the ui build duration in nanoseconds'"
        )

        repo().query(
          "COMMENT ON COLUMN docker_run_measurements.listeners_duration IS 'This is the listeners execution duration in nanoseconds'"
        )
      end,
      fn ->
        nil
      end
    )

    execute("CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";")

    execute(
      "INSERT INTO app_user_session(uuid, user_id, application_id, build_number, inserted_at, updated_at) SELECT uuid_generate_v4(), c.user_id, a.id, b.id, c.inserted_at, c.updated_at FROM
        client_app_measurements c
          JOIN applications a ON c.application_name = a.service_name
          JOIN (SELECT b.id, b.creator_id FROM builds b, applications a WHERE a.id=application_id ORDER BY b.id DESC LIMIT 1) b
          ON a.creator_id=b.creator_id;"
    )

    execute(
      "INSERT INTO socket_app_measurements(app_user_session_uuid, duration, inserted_at, updated_at) SELECT s.uuid, c.duration, c.inserted_at, c.updated_at FROM client_app_measurements c
      JOIN applications a ON c.application_name = a.service_name
      JOIN app_user_session s ON s.application_id=a.id;"
    )

    drop(table(:client_app_measurements))
  end

  def down do
    create table(:client_app_measurements) do
      add(:user_id, references(:users), null: false)
      add(:application_name, :string, null: false)
      add(:duration, :bigint, null: false)

      timestamps()
    end

    execute(
      fn ->
        repo().query("COMMENT ON COLUMN client_app_measurements.duration IS 'This is the duration in nanoseconds'")
      end,
      fn ->
        nil
      end
    )

    execute(
      "INSERT INTO client_app_measurements(user_id,application_name, duration, inserted_at, updated_at) SELECT s.user_id, a.name, m.duration, s.inserted_at, s.updated_at FROM app_user_session s JOIN
       applications a ON s.application_id=a.id JOIN socket_app_measurements m ON s.uuid=m.app_user_session_uuid;"
    )

    alter table(:openfaas_runaction_measurements) do
      add(:user_id, references(:users), null: true)
      add(:application_name, :string, null: true)
    end

    execute("UPDATE openfaas_runaction_measurements SET user_id=s.user_id, application_name=a.service_name
      FROM action_logs l JOIN app_user_session s ON l.app_user_session_uuid=s.uuid
      JOIN applications a ON a.id=s.application_id WHERE openfaas_runaction_measurements.action_logs_uuid=l.uuid;")

    alter table(:openfaas_runaction_measurements) do
      modify(:user_id, references(:users), null: false, from: references(:users))
      modify(:application_name, :string, null: false, from: :string)
      remove(:action_logs_uuid, references(:action_logs, column: :uuid, type: :uuid))
    end

    execute("DROP TABLE app_user_session,action_logs,docker_run_measurements,socket_app_measurements;")
  end
end
