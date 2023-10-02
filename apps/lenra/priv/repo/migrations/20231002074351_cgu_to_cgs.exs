defmodule Lenra.Repo.Migrations.CguToCgs do
  use Ecto.Migration

  def change do
    rename(table(:user_accept_cgu_versions), :cgu_id, to: :cgs_id)
    rename(table(:cgu), to: table(:cgs))
    rename(table(:user_accept_cgu_versions), to: table(:user_accept_cgs_versions))


    execute("DROP TRIGGER IF EXISTS check_version_cgu_is_latest ON user_accept_cgu_versions;")
    execute("DROP FUNCTION IF EXISTS check_version_cgu() CASCADE;")

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
