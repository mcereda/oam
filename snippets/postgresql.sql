-- Add '+' to psql commands to get more information


-- Show help
help

-- Show available SQL commands
\h

-- Show available psql commands
\?


-- Show connection information
\conninfo


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

-- Change database settings for the current session
SET pgaudit.log = 'none';
SET password_encryption  = 'scram-sha-256';

-- Change database settings permanently
ALTER DATABASE reviser SET pgaudit.log TO 'none';

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
\dt+


-- Revoke *default* privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA cache REVOKE select ON TABLES FROM sales;
ALTER DEFAULT PRIVILEGES FOR ROLE juan IN SCHEMA cache REVOKE all ON TABLES FROM sales;


-- List users with respective roles
\du
\du+
-- List users only
select usename FROM pg_catalog.pg_user;

-- Check the current user has SuperUser permissions
SHOW is_superuser

-- Create roles
-- Does *not* support IF NOT EXISTS
CREATE ROLE miriam;
CREATE ROLE miriam WITH LOGIN PASSWORD 'jw8s0F4' VALID UNTIL '2005-01-01';

-- Create users
-- Does *not* support IF NOT EXISTS
CREATE USER mike;

-- Grant users SuperUser permissions
-- Executing user must be already SuperUser
ALTER USER joel WITH SUPERUSER;
-- Revoke SuperUser permissions
ALTER USER joel WITH NOSUPERUSER;
-- Grant privileges to users
ALTER USER mark CREATEDB;
ALTER ROLE miriam CREATEROLE CREATEDB;
-- Change passwords
ALTER USER jonathan WITH PASSWORD 'seagull5-pantomime-Resting';
ALTER ROLE samantha WITH PASSWORD 'Wing5+Trunks3+Relic2' VALID UNTIL 'August 4 12:00:00 2024 +1';
-- Change password's validity
ALTER ROLE fred VALID UNTIL 'infinity';


-- Close the connection to the current DB
\q
\quit


-- Get passwords
SELECT rolpassword from pg_authid where rolname = 'admin';


-- Show extensions
\dx
SELECT * FROM pg_extension;
SELECT extname FROM pg_extension;

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
