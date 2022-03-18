defmodule Lenra.Repo.Migrations.NewDataSchema do
  use Ecto.Migration

  def change do
    defmodule ApplicationRunner.Repo.Migrations.Data do
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
          "INSERT INTO temp_datastores VALUES(SELECT * FROM datastores)",
          "INSERT INTO datastores VALUES(SELECT * FROM temp_datastores)"
        )

        remove(table(:datastores))

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
      end
    end
  end
end
