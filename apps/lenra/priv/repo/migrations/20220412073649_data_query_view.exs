defmodule Lenra.Repo.Migrations.DataQueryView do
  use Ecto.Migration

  def change do
    # change :refBy_id to :ref_by_id
    alter table(:data_references) do
      remove(:refBy_id, references(:datas), null: false)
      add(:ref_by_id, references(:datas, on_delete: :delete_all), null: false)
    end

    # Update the index accordingly
    create(unique_index(:data_references, [:refs_id, :ref_by_id], name: :data_references_refs_id_ref_by_id))

    # Create the view to send the query on.
    # 3 fields:
    # id -> id of the data
    # environment_id -> Self explainatory
    # data -> the json object that represent the data with refs/datastore/userData...
    # This allow to query every field exactly like classic user data.
    # This migration will be copy on server/devtools to create the same view.
    # "_user" field will only be added if we are on "_users" datastore
    # "_refs" and "_refBy" field will be empty array if there is no references (instead of null)
    execute(
      "
    CREATE VIEW data_query_view AS
    SELECT
    d.id as id,
    ds.environment_id as environment_id,
    jsonb_build_object(
      '_datastore', ds.name,
      '_id', d.id,
      '_data', d.data,
      '_refs', (SELECT COALESCE((SELECT jsonb_agg(dr.refs_id) FROM data_references as dr where ref_by_id = d.id GROUP BY dr.ref_by_id), '[]'::jsonb)),
      '_refBy', (SELECT COALESCE((SELECT jsonb_agg(dr.ref_by_id) FROM data_references as dr where refs_id = d.id GROUP BY dr.refs_id), '[]'::jsonb))
    ) ||
    CASE  WHEN ds.name != '_users' THEN '{}'::jsonb
          WHEN ds.name = '_users' THEN jsonb_build_object(
            '_user', (SELECT row_to_json(_) FROM (SELECT u.email, u.id) AS _)
          )
    END
    as data
      FROM datas AS d
      INNER JOIN datastores AS ds ON (ds.id = d.datastore_id)
      LEFT JOIN user_datas AS ud ON (ud.data_id = d.id)
      LEFT JOIN users AS u ON (u.id = ud.user_id);
    ",
      "DROP VIEW IF EXISTS data_query_view"
    )
  end
end
