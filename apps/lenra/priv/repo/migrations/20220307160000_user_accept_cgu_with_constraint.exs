defmodule Lenra.Repo.Migrations.UserAcceptCguWithConstraint do
  use Ecto.Migration

  def up do
    execute("CREATE OR REPLACE FUNCTION check_version_cgu()
    RETURNS TRIGGER AS $func$
      DECLARE
        last_version_id bigint;
      BEGIN
        SELECT id into last_version_id FROM cgu ORDER BY inserted_at DESC LIMIT 1;
        IF last_version_id = NEW.cgu_id THEN
          RETURN NEW;
        ELSE
          RAISE EXCEPTION 'Not latest CGS';
        END IF;
      END;
    $func$ LANGUAGE plpgsql;")

    execute("CREATE TRIGGER check_version_cgu_is_latest
    BEFORE INSERT OR UPDATE ON user_accept_cgu_versions
    FOR EACH ROW EXECUTE PROCEDURE check_version_cgu();")
  end

  def down do
    execute("DROP FUNCTION IF EXISTS check_version_cgu() CASCADE;")

    execute("DROP TRIGGER IF EXISTS check_version_cgu_is_latest ON user_accept_cgu_versions;")
  end
end
