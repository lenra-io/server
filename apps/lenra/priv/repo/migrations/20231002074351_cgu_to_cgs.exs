defmodule Lenra.Repo.Migrations.CguToCgs do
  use Ecto.Migration

  def change do
    execute("DROP TRIGGER IF EXISTS check_version_cgu_is_latest ON user_accept_cgu_versions;")
    execute("DROP FUNCTION IF EXISTS check_version_cgu() CASCADE;")

    drop(unique_index(:cgu, [:path]))
    drop(unique_index(:cgu, [:hash]))
    drop(unique_index(:cgu, [:version]))

    drop(unique_index(:user_accept_cgu_versions, [:user_id, :cgu_id], name: :user_id_cgu_id_unique_index))
    drop(index(:user_accept_cgu_versions, [:user_id]))
    drop(index(:user_accept_cgu_versions, [:cgu_id]))

    rename(table(:user_accept_cgu_versions), :cgu_id, to: :cgs_id)
    rename(table(:cgu), to: table(:cgs))
    rename(table(:user_accept_cgu_versions), to: table(:user_accept_cgs_versions))
    execute("ALTER INDEX user_accept_cgu_versions_pkey RENAME TO user_accept_cgs_versions_pkey")

    execute(
      "ALTER TABLE user_accept_cgs_versions RENAME CONSTRAINT user_accept_cgu_versions_user_id_fkey TO user_accept_cgs_versions_user_id_fkey"
    )

    create(unique_index(:cgs, [:path]))
    create(unique_index(:cgs, [:hash]))
    create(unique_index(:cgs, [:version]))

    create(index(:user_accept_cgs_versions, [:user_id]))
    create(index(:user_accept_cgs_versions, [:cgs_id]))
    create(unique_index(:user_accept_cgs_versions, [:user_id, :cgs_id], name: :user_id_cgs_id_unique_index))

    execute("CREATE OR REPLACE FUNCTION check_version_cgs()
    RETURNS TRIGGER AS $func$
      DECLARE
        last_version_id bigint;
      BEGIN
        SELECT id into last_version_id FROM cgs ORDER BY inserted_at DESC LIMIT 1;
        IF last_version_id = NEW.cgs_id THEN
          RETURN NEW;
        ELSE
          RAISE EXCEPTION 'Not latest CGS';
        END IF;
      END;
    $func$ LANGUAGE plpgsql;")

    execute("CREATE TRIGGER check_version_cgs_is_latest
    BEFORE INSERT OR UPDATE ON user_accept_cgs_versions
    FOR EACH ROW EXECUTE PROCEDURE check_version_cgs();")
  end
end
