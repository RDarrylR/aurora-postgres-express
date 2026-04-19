-- Demo schema for the Aurora Express sample app.
-- Express configuration does not support --database-name at creation time,
-- so the cluster starts with only the default "postgres" database.
-- Create the app database first, then connect to it to run the rest.
--
-- Usage:
--   psql "host=$DB_ENDPOINT user=postgres dbname=postgres sslmode=verify-full sslrootcert=system" \
--        -c "CREATE DATABASE appdb;" 2>/dev/null || true
--   psql "host=$DB_ENDPOINT user=postgres dbname=appdb sslmode=verify-full sslrootcert=system" \
--        -f schema.sql

CREATE TABLE IF NOT EXISTS notes (
    id         BIGSERIAL PRIMARY KEY,
    title      TEXT        NOT NULL,
    body       TEXT        NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS notes_created_at_idx ON notes (created_at DESC);

-- Grant the app role access. The express cluster creates the admin `postgres`
-- user automatically. The app role below is created the first time this
-- schema is applied and is mapped to IAM auth.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_user') THEN
        CREATE ROLE app_user WITH LOGIN;
    END IF;
END
$$;

GRANT rds_iam TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON notes TO app_user;
GRANT USAGE, SELECT ON SEQUENCE notes_id_seq TO app_user;
