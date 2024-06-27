-- Close the connection to the current DB
\q

-- Show extensions.
SELECT "*" FROM "pg_extension";
SELECT "extname" FROM "pg_extension";

-- Add extensions
CREATE EXTENSION "pg_transport";
CREATE EXTENSION IF NOT EXISTS "pgaudit";

-- Remove extensions
DROP EXTENSION "plpgsql", "btree_gist", … CASCADE;


-- Simulate DB transfers
-- Requires 'pg_transport' to be installed on both the source and destination DBs
-- Requires 'pg_transport' to be the *only* extension active on the source
SELECT transport.import_from_server(
  'up.to.63.chars.source.fqdn', 5432,
  'source.username', 'source.password', 'source.db',
  'destination.password',
  true
);
-- Run DB transfers
-- Requires 'pg_transport' to be installed on both the source and destination DBs
-- Requires 'pg_transport' to be the *only* extension active on the source
SELECT transport.import_from_server(
  'up.to.63.chars.source.fqdn', 5432,
  'source.username', 'source.password', 'source.db',
  'destination.password',
  false
);
