defmodule Lenra.Repo.Migrations.UserAcceptCguWithConstraint do
  use Ecto.Migration

  def up do
    execute("CREATE OR REPLACE FUNCTION check_version_cgu()
    RETURNS TRIGGER AS $func$
      DECLARE
        last_version varchar;
        cgu_version varchar;
      BEGIN
        SELECT cgu.version into last_version FROM cgu ORDER BY cgu.inserted_at ASC LIMIT 1;
        SELECT cgu.version into cgu_version FROM cgu WHERE cgu.id = NEW.cgu_id;
        IF last_version = cgu_version THEN
          RETURN NEW;
        ELSE
          RAISE EXCEPTION 'Not latest CGU';
        END IF;
      END;
    $func$ LANGUAGE plpgsql;")

    execute("CREATE TRIGGER check_version_cgu_is_latest
    BEFORE INSERT ON user_accept_cgu_versions
    EXECUTE PROCEDURE check_version_cgu();")
  end

  def down do
    execute("DROP FUNCTION IF EXISTS check_version_cgu() CASCADE;")

    execute("DROP TRIGGER IF EXISTS check_version_cgu_is_latest ON permits;")
  end
end
