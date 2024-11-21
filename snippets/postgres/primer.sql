-- Single line comment
/*
 * multi-line comment
 */

-- Add '+' to psql commands to get more information


-- Show help
help

-- Show available SQL commands
\h

-- Show available psql commands
\?


-- Show PostgreSQL version
SELECT version();

-- Show connection information
\conninfo


-- Load extensions globally in the instance
-- If supported (no RDS)
ALTER SYSTEM SET shared_preload_libraries = 'anon';
ALTER DATABASE postgres SET session_preload_libraries = 'anon';


-- List databases
\l
\list+
SELECT datname FROM pg_database;

-- Create databases
CREATE DATABASE world;

-- Show database settings
SELECT * FROM pg_settings;
SELECT "name", "setting" FROM pg_settings WHERE NAME LIKE '%log%';
SHOW "wal_keep_size";
SHOW "password_encryption";
SHOW "pgaudit.log";

-- Change database settings *for the current session* only
SET pgaudit.log = none;
SET password_encryption = scram-sha-256;

-- Change database settings permanently
-- Will *not* be active for the current session, logout and login again to see the change
ALTER DATABASE reviser SET pgaudit.log TO none;

-- Switch between databases
\c sales
\connect vendor


-- List schemas
\dn
SELECT schema_name FROM information_schema.schemata;
SELECT nspname FROM pg_catalog.pg_namespace;

-- Create schemas
CREATE SCHEMA mundane;
CREATE SCHEMA IF NOT EXISTS mundane AUTHORIZATION joe;

-- Remove schemas
DROP SCHEMA mundane;
DROP SCHEMA IF EXISTS mundane CASCADE;


-- List tables
\d
\dt
\dt+

-- Create tables
CREATE TABLE people (
  id          char(2)      PRIMARY KEY,
  first_name  varchar(40)  NOT NULL,
  last_name   text(40)     NOT NULL,
  phone       varchar(20)
);

-- Show table structure
-- Includes constraints
\d sales
\d+ clients
SELECT column_name, data_type, character_maximum_length FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = 'vendors';


-- Insert data
INSERT INTO people(id, first_name, last_name, phone)
VALUES
  ('T1', 'Sarah', 'Conor', '0609110911'),
  ('wa', 'Wally', 'Polly', null);


-- Revoke *default* privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA cache REVOKE select ON TABLES FROM sales;
ALTER DEFAULT PRIVILEGES FOR ROLE juan IN SCHEMA cache REVOKE all ON TABLES FROM sales;


-- List users with respective roles
\du
\du+ mark
-- List users only
SELECT usename FROM pg_catalog.pg_user;
-- List roles only
SELECT rolname FROM pg_catalog.pg_roles;

-- Check the current user has SuperUser privileges
SHOW is_superuser;

-- Create roles
-- Roles *are* users *and* groups since PostgreSQL vFIXME
-- Users are just roles that can LOGIN
-- Does *not* support IF NOT EXISTS
CREATE ROLE miriam;
CREATE ROLE miriam WITH LOGIN PASSWORD 'jw8s0F4' VALID UNTIL '2005-01-01';
CREATE USER mike IN ROLE engineers;

-- Grant roles SuperUser privileges
-- The role granting privileges must be already SuperUser
ALTER USER joel WITH SUPERUSER;

-- Revoke SuperUser privileges
ALTER USER joel WITH NOSUPERUSER;

-- Grant privileges to users
ALTER USER mark CREATEDB REPLICATION;
ALTER ROLE miriam CREATEROLE CREATEDB;

-- Change passwords
ALTER USER mike WITH PASSWORD NULL;
ALTER USER jonathan WITH PASSWORD 'seagull5-pantomime-Resting';
ALTER ROLE samantha WITH PASSWORD 'Wing5+Trunks3+Relic2' VALID UNTIL 'August 4 12:00:00 2024 +1';

-- Change password's validity
ALTER ROLE fred VALID UNTIL 'infinity';
ALTER ROLE samantha VALID UNTIL 'August 4 12:00:00 2024 +1';

-- Reset password expiration date to NULL
UPDATE pg_authid SET rolvaliduntil = NULL WHERE rolname == 'lucas';
-- For everybody
UPDATE pg_authid
SET rolvaliduntil = NULL
WHERE rolname IN (
  SELECT rolname
  FROM pg_authid
  WHERE rolvaliduntil IS NOT NULL
);

-- Rename roles
ALTER ROLE manager RENAME TO boss;

-- Assign roles to users or other roles
GRANT rds_superuser TO mike;

-- Assume roles for the current session
SET ROLE admin;

-- Remove role memberships from users
REVOKE engineers FROM mike;


-- List permissions
-- on tables
SELECT *
FROM information_schema.role_table_grants
WHERE grantee = 'darwin';
-- about ownership
SELECT *
FROM pg_tables
WHERE tableowner = 'darwin';
-- on schemas
SELECT
  r.usename AS grantor,
  e.usename AS grantee,
  nspname,
  privilege_type,
  is_grantable
FROM pg_namespace
JOIN LATERAL (
  SELECT *
  FROM aclexplode(nspacl) AS x
) a ON true
JOIN pg_user e ON a.grantee = e.usesysid
JOIN pg_user r ON a.grantor = r.usesysid
WHERE e.usename IN ('darwin', 'salesmen');
-- detailed
SELECT grantor, grantee, table_schema, table_name, privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'engineers';

-- Assign permissions
GRANT USAGE ON SCHEMA bar_schema TO donald;


-- Close the connection to the current DB
\q
\quit


-- Get passwords
SELECT rolpassword from pg_authid where rolname = 'admin';


-- Show available extensions
SELECT name FROM pg_available_extensions ORDER BY name;

-- Show installed extensions
\dx
SELECT * FROM pg_extension;
SELECT extname FROM pg_extension ORDER BY extname;

-- Show extensions versions
SELECT postgis_version(), postgis_full_version(), postgis_lib_version();

-- Add extensions
CREATE EXTENSION pg_transport;
CREATE EXTENSION IF NOT EXISTS pgaudit;

-- Remove extensions
DROP EXTENSION plpgsql;
DROP EXTENSION IF EXISTS plpgsql, btree_gist, … CASCADE;


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


-- List replication slots
SELECT * FROM pg_replication_slots;

-- Create replication slots
-- Requires the executor to be superuser or replication role
SELECT pg_create_physical_replication_slot('peerflow_slot_prod');
SELECT pg_create_logical_replication_slot('airbyte_slot', 'pgoutput');

-- Drop replication slots
SELECT pg_drop_replication_slot('airbyte_slot');


-- List publications
\dRp
\dRp+

-- Create publications
CREATE PUBLICATION peerflow_prod FOR ALL TABLES;
CREATE PUBLICATION airbyte FOR TABLE call_log, queue_log;


-- Wildcards
-- '%' = zero or more characters
-- '_' = exactly 1 character
SELECT * FROM users WHERE name LIKE '% Banda';  -- ends with ' Banda'
SELECT name FROM customers WHERE name LIKE '%banda%';  -- contains 'banda'
SELECT id FROM customers WHERE City LIKE 'L___on';  -- starts with 'L', followed by any 3 characters, followed by 'on'


-- Comparison with lists
SELECT * FROM users WHERE username IN ('matthew', 'lucas', 'todd', 'roxy', 'kyle', 'ken', 'gideon');
SELECT * FROM users WHERE username NOT IN ('knives', 'wallace');


-- Shuffle columns
-- needs some identifier for the join and where clauses - either use primary key or ctid
-- source: https://stackoverflow.com/questions/33555524/postgresql-shuffle-column-values#33555639
WITH
  ids AS (   SELECT row_number() OVER (ORDER BY random()) row_num, vendor_id   AS new_vendor_id   FROM vendors ),
  names AS ( SELECT row_number() OVER (ORDER BY random()) row_num, vendor_name AS new_vendor_name FROM vendors )
UPDATE vendors
  SET vendor_id = new_vendor_id, vendor_name = new_vendor_name FROM ids JOIN names ON ids.row_num = names.row_num
  WHERE vendor_id = new_vendor_id;
--
WITH
  __ctids_in_order AS ( SELECT ROW_NUMBER() OVER (),                  ctid                           FROM vendors ),
  __shuffled_names AS ( SELECT ROW_NUMBER() OVER (ORDER BY RANDOM()), vendor_name AS new_vendor_name FROM vendors )
UPDATE vendors
  SET vendor_name = __shuffled_names.new_vendor_name
  FROM __shuffled_names JOIN __ctids_in_order ON __shuffled_names.row_number = __ctids_in_order.row_number
  WHERE vendors.ctid = __ctids_in_order.ctid

-- Deterministic random values
SELECT setseed(0.25), round(random()::DECIMAL, 15) AS random_number;  -- seed must be in [-1:1]


-- Search values in all tables
-- source: https://stackoverflow.com/questions/5350088/how-to-search-a-specific-value-in-all-tables-postgresql/23036421#23036421
--         └── https://github.com/dverite/postgresql-functions/tree/master/global_search


-- Functions
-- Refer <https://www.postgresql.org/docs/current/sql-createfunction.html>
\df
\df+ to_char
\df+ hash*
SELECT routine_name FROM information_schema.routines WHERE routine_type = 'FUNCTION';
SELECT p.proname FROM pg_catalog.pg_namespace n JOIN pg_catalog.pg_proc p ON p.pronamespace = n.oid WHERE p.prokind = 'f';

CREATE OR REPLACE FUNCTION return_1() RETURNS INTEGER LANGUAGE SQL RETURN 1;

-- Show functions definition
\sf hash_numeric
\sf+ hashfloat8

-- Given hash_national_ids(country TEXT, table_name TEXT, column_name DEFAULT 'national_id')
SELECT hash_national_ids('estonia', 'clients');
SELECT hash_national_ids(country => 'estonia', table_name => 'clients', column_name => 'national_id');


-- Type casting
SELECT pg_typeof(10);
SELECT
  CAST ('21' AS INTEGER), 420.69::INTEGER,
  CAST('100' AS DOUBLE PRECISION), '100.93'::FLOAT,
  CAST ('true' AS BOOLEAN),
  CAST('2024-02-01 12:34:56' AS DATE), '01-OCT-2015' ::DATE,
  CAST('2016-11-11' AS TIMESTAMP), '2016-11-11'::TIMESTAMP,
  CAST ('15 minute' AS INTERVAL), '3 month' :: INTERVAL,
  CAST ('20 days' AS TEXT), '24 hour':: TEXT,
  CAST (ARRAY[1,3,5] AS TEXT),
  CAST (B'1001' AS INTEGER), x'123abc'::int,
  '{1,2,3}'::INTEGER[] AS result_array;
SELECT to_char(42, '0000');  -- '0042'
SELECT to_number('12,454.9', '99G999D9S');


-- Atomic actions
BEGIN;
  -- add ON UPDATE CASCADE to the 'signups_customer_id_fkey' constraint
  -- ALTER TABLE 'x' ALTER CONSTRAINT does not support this action at the time of writing
  ALTER TABLE signups RENAME CONSTRAINT signups_customer_id_fkey TO delete_me;
  ALTER TABLE signups ADD CONSTRAINT signups_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES customers(id) ON UPDATE CASCADE;
  ALTER TABLE signups DROP CONSTRAINT delete_me;
COMMIT;
BEGIN;
  ALTER TABLE customers RENAME COLUMN phone TO phone_old;
  ALTER TABLE customers ADD COLUMN phone text UNIQUE;
COMMIT;


-- Timezones
SELECT * FROM pg_timezone_names;
-- Time functions
SELECT
  NOW(), CURRENT_TIME, CURRENT_TIMESTAMP,       -- current date and time *with* the time zone of the server
  NOW()::timestamp, LOCALTIME, LOCALTIMESTAMP,  -- current date and time *without* time zone
  TIMEOFDAY();


-- Search
SELECT table_schema, table_name, column_name
FROM information_schema.columns
WHERE column_name LIKE '%national_id%';


-- Loops
DO $$
  DECLARE hashed_i TEXT;
  BEGIN
    FOR i IN 1..150000
    LOOP
      hashed_i = LPAD(ABS(SUBSTRING(DIGEST(i::TEXT, 'sha1')::TEXT, 2, 8)::BIT(32)::INT/2.147483647)::INT::TEXT, 8, '0');
      IF hashed_i LIKE '00%' THEN
        RAISE NOTICE '%: %', i, hashed_i;
      END IF;
    END LOOP;
  END;
$$;
DO $$
  DECLARE column_info RECORD;  -- required to use select in for definition
  BEGIN
    FOR column_info IN
      SELECT table_schema AS schema, table_name AS table, column_name AS column
      FROM information_schema.columns
      WHERE column_name LIKE '%sensitive%'
    LOOP
      RAISE NOTICE 'target: %.%.%', column_info.schema, column_info.table, column_info.column;
      PERFORM hash_data(column_info.table, column_info.column, column_info.schema);
    END LOOP;
  END;
$$;


-- Strings
-- escape single quotes by doubling them (' -> '')
query = 'SELECT table_schema AS schema, table_name AS table, column_name AS column FROM information_schema.columns WHERE column_name LIKE ''%national_id%''';
SELECT ENCODE('something'::BYTEA, 'base64');
SELECT CONVERT_FROM(DECODE('c29tZXRoaW5n', 'base64'), 'UTF-8');


ALTER TABLE customers RENAME COLUMN phone TO phone_numbers;
ALTER TABLE signups RENAME CONSTRAINT signups_customer_id_fkey TO something_blue;
ALTER TABLE vendors SET CONSTRAINT vendors_value_uindex DEFERRED;


-- Show all constraints in the current DB
SELECT
  ns.nspname AS schema,
  class.relname AS "table",
  con.conname AS "constraint",
  con.contype AS "type",
  con.condeferrable AS "deferrable",
  con.condeferred AS "deferred"
FROM pg_constraint con
  INNER JOIN pg_class class ON class.oid = con.conrelid
  INNER JOIN pg_namespace ns ON ns.oid = class.relnamespace
WHERE ns.nspname != 'pg_catalog'
ORDER BY 1, 2, 3;
-- Show all uniqueness constraints in the current DB
SELECT
  ns.nspname AS schema,
  class.relname AS "table",
  con.conname AS "constraint",
  con.condeferrable AS "deferrable",
  con.condeferred AS "deferred"
FROM pg_constraint con
  INNER JOIN pg_class class ON class.oid = con.conrelid
  INNER JOIN pg_namespace ns ON ns.oid = class.relnamespace
WHERE
  con.contype IN ('u') AND
  ns.nspname != 'pg_catalog'
ORDER BY 1, 2, 3;


-- List all uniqueness constraints in a schema
SELECT
  class.relname AS "table",
  con.conname AS "constraint",
  con.condeferrable AS "deferrable",
  con.condeferred AS "deferred"
FROM pg_constraint con
  INNER JOIN pg_class class ON class.oid = con.conrelid
  INNER JOIN pg_namespace ns ON ns.oid = class.relnamespace
WHERE
  con.contype IN ('u') AND
  ns.nspname = 'public'
ORDER BY 1, 2, 3;


-- Empty tables of their data
TRUNCATE TABLE sales;
