defmodule Lenra.Repo.Migrations.NewDataSchema do
  use Ecto.Migration

  def change do
    create table(:temp_datastores) do
      add(:user_id, :int)
      add(:application_id, :id)
      add(:data, :map)
      add(:name, :string)

      timestamps()
    end

    execute(
      "INSERT INTO temp_datastores(user_id, application_id, data, inserted_at, updated_at) SELECT user_id, application_id, data, inserted_at, updated_at FROM datastores",
      "INSERT INTO datastores(user_id, application_id, data, inserted_at, updated_at) SELECT user_id, application_id, data, inserted_at, updated_at FROM temp_datastores"
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

    execute(
      "INSERT INTO datastores(environment_id,name, inserted_at, updated_at) SELECT env.id, 'UserDatas', t.inserted_at, t.updated_at FROM environments AS env LEFT JOIN temp_datastores AS t ON t.application_id = env.application_id"
    )

    execute(
      "INSERT INTO datas(datastore_id, data, inserted_at, updated_at) SELECT d.id, t.data, t.inserted_at, t.updated_at FROM temp_datastores AS t LEFT JOIN environments AS env ON t.application_id = env.id LEFT JOIN datastores AS d ON d.environment_id = env.id"
    )

    execute(
      "INSERT INTO user_datas(user_id, data_id, inserted_at, updated_at) SELECT t.user_id, d.id, t.inserted_at, t.updated_at FROM temp_datastores AS t LEFT JOIN environments AS env ON t.application_id = env.id LEFT JOIN datastores AS d ON d.environment_id = env.id"
    )

    drop(table(:temp_datastores))
  end
end
