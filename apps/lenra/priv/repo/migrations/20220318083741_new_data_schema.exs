defmodule Lenra.Repo.Migrations.NewDataSchema do
  use Ecto.Migration

  def up() do
    create table(:temp_datastores) do
      add(:user_id, :int)
      add(:application_id, :id)
      add(:data, :map)
      add(:name, :string)

      timestamps()
    end

    execute(
      "INSERT INTO temp_datastores(user_id, application_id, data, inserted_at, updated_at) SELECT user_id, application_id, data, inserted_at, updated_at FROM datastores"
    )

    drop(table(:datastores))

    create table(:datastores) do
      add(:environment_id, references(:environments), null: false)
      add(:name, :string)

      timestamps()
    end

    create(unique_index(:datastores, [:name, :environment_id], name: :datastores_name_application_id_index))

    create table(:datas) do
      add(:datastore_id, references(:datastores, on_delete: :delete_all), null: false)
      add(:data, :map, null: false)

      timestamps()
    end

    create table(:user_datas) do
      add(:user_id, references(:users), null: false)
      add(:data_id, references(:datas), null: false)

      timestamps()
    end

    create(unique_index(:user_datas, [:user_id, :data_id], name: :user_datas_user_id_data_id))

    create table(:data_references) do
      add(:refs_id, references(:datas, on_delete: :delete_all), null: false)
      add(:refBy_id, references(:datas, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:data_references, [:refs_id, :refBy_id], name: :data_references_refs_id_refBy_id))

    execute("CREATE FUNCTION check_user_datas() RETURNS trigger LANGUAGE plpgsql as $$
        DECLARE
        env_id bigint;
        BEGIN
          SELECT ds.environment_id INTO env_id FROM datastores AS ds LEFT JOIN datas AS d ON d.datastore_id = ds.id WHERE NEW.data_id = d.id;
          IF 1 <= (SELECT COUNT(*) FROM datas AS d LEFT JOIN user_datas AS u ON u.data_id = d.id LEFT JOIN datastores AS ds ON ds.id = d.datastore_id WHERE new.user_id = u.user_id AND ds.environment_id = env_id GROUP BY ds.environment_id) THEN
            RAISE EXCEPTION 'user already have user_data for this environment';
          END IF;
          RETURN NEW;
        END;
    $$")

    execute("CREATE TRIGGER only_one_user_data_per_environment
    BEFORE INSERT OR UPDATE ON user_datas
    FOR EACH ROW EXECUTE procedure check_user_datas()")

    execute(
      "INSERT INTO datastores(environment_id, name, inserted_at, updated_at) SELECT env.id, 'UserDatas', t.inserted_at, t.updated_at FROM environments AS env LEFT JOIN temp_datastores AS t ON t.application_id = env.application_id"
    )

    execute(
      "INSERT INTO datas(datastore_id, data, inserted_at, updated_at) SELECT d.id, t.data, t.inserted_at, t.updated_at FROM temp_datastores AS t LEFT JOIN environments AS env ON t.application_id = env.id LEFT JOIN datastores AS d ON d.environment_id = env.id"
    )

    execute(
      "INSERT INTO user_datas(user_id, data_id, inserted_at, updated_at) SELECT t.user_id, d.id, t.inserted_at, t.updated_at FROM temp_datastores AS t LEFT JOIN environments AS env ON t.application_id = env.id LEFT JOIN datastores AS d ON d.environment_id = env.id"
    )

    drop(table(:temp_datastores))
  end

  def down() do
    create table(:temp_datastores) do
      add(:environment_id, :id, null: false)
      add(:name, :string)

      timestamps()
    end

    create table(:temp_datas) do
      add(:datastore_id, :id, null: false)
      add(:data, :map, null: false)

      timestamps()
    end

    create table(:temp_user_datas) do
      add(:user_id, :id, null: false)
      add(:data_id, :id, null: false)

      timestamps()
    end

    execute(
      "INSERT INTO temp_datastores(environment_id, name, inserted_at, updated_at) SELECT environment_id, name, inserted_at, updated_at FROM datastores"
    )

    execute(
      "INSERT INTO temp_datas(datastore_id, data, inserted_at, updated_at) SELECT datastore_id, data, inserted_at, updated_at FROM datas"
    )

    execute(
      "INSERT INTO temp_user_datas(user_id, data_id, inserted_at, updated_at) SELECT user_id, data_id, inserted_at, updated_at FROM user_datas"
    )

    execute("DROP TRIGGER only_one_user_data_per_environment ON user_datas")

    execute("DROP FUNCTION check_user_datas")

    drop(unique_index(:data_references, [:refs_id, :refBy_id], name: :data_references_refs_id_refBy_id))

    drop(table(:data_references))

    drop(unique_index(:user_datas, [:user_id, :data_id], name: :user_datas_user_id_data_id))

    drop(table(:user_datas))

    drop(table(:datas))

    drop(table(:datastores))

    create table(:datastores) do
      add(:user_id, references(:users))
      add(:application_id, references(:applications))
      add(:data, :map)
      timestamps()
    end

    create(unique_index(:datastores, [:user_id, :application_id], name: :datastores_user_id_application_id_index))

    execute(
      "INSERT INTO datastores(user_id, application_id, data, inserted_at, updated_at) SELECT u.user_id, main.application_id, d.data, t.inserted_at, t.updated_at FROM temp_datastores AS t
      LEFT JOIN application_main_environment AS main ON main.environment_id = t.environment_id
      LEFT JOIN temp_datas AS d ON d.datastore_id = t.id
      LEFT JOIN temp_user_datas AS u ON d.id = u.data_id"
    )

    drop(table(:temp_datastores))
    drop(table(:temp_datas))
    drop(table(:temp_user_datas))
  end
end
