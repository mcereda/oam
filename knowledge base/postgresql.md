# PostgreSQL

1. [TL;DR](#tldr)
1. [Functions](#functions)
1. [Extensions of interest](#extensions-of-interest)
   1. [PostGIS](#postgis)
   1. [`postgresql_anonymizer`](#postgresql_anonymizer)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

One can store one's credentials in `~/.pgpass`:

```plaintext
# line format => hostname:port:database:username:password`
# can use wildcards
postgres.lan:5643:postgres:postgres:BananaORama
*:*:sales:elaine:modestPassword
```

The credential file's permissions must be `0600`, or it will be ignored.

Database roles represent both users and groups.<br/>
Roles are **distinct** from the OS' users and groups, and are global across the whole installation (there are **no**
DB-specific roles).

Extensions in PostgreSQL are managed per database.

<details>
  <summary>Setup</summary>

```sh
# Installation.
brew install 'postgresql@16'
sudo dnf install 'postgresql' 'postgresql-server'
sudo zypper install 'postgresql15' 'postgresql15-server'

# Set the password in environment variables.
export PGPASSWORD='securePassword'

# Set up the credentials file.
cat <<EOF > ~/'.pgpass'
postgres.lan:5643:postgres:postgres:BananaORama
*:*:sales:elaine:modestPassword
EOF
chmod '600' ~/'.pgpass'

# Set up the per-user services file.
# do *not* use spaces around the '=' sign.
cat <<EOF > ~/'.pg_service.conf'
[prod]
host=prod.0123456789ab.eu-west-1.rds.amazonaws.com
port=5433
user=master
EOF
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Connect to servers via CLI client.
# If not given:
# - the hostname defaults to 'localhost';
# - the port defaults to '5432';
# - the username defaults to the current user;
# - the 'sslmode' parameter defaults to 'prefer'.
psql 'my-db'
psql 'my-db' 'user'
psql 'postgres://host'
psql 'postgresql://host:5433/my-db?sslmode=require'
psql -U 'username' -d 'my-db' -h 'hostname' -p 'port' -W
psql --host 'host.fqnd' --port '5432' --username 'postgres' --database 'postgres' --password
psql "service=prod sslmode=disable"

# List available databases.
psql … --list

# Execute commands.
psql 'my-db' … -c 'select * from tableName;' -o 'out.file'
psql 'my-db' … -c 'select * from tableName;' -H
psql 'my-db' … -f 'commands.sql'

# Initialize a test DB.
pgbench -i 'test-db'
pgbench -i 'test-db' -h 'hostname' -p '5555' -U 'user'

# Create full backups of databases.
pg_dump -U 'postgres' -d 'sales' -F 'custom' -f 'sales.bak'
pg_dump --host 'host.fqnd' --port '5432' --username 'postgres' --dbname 'postgres' --password --schema-only
pg_dump … -T 'customers,orders' -t 'salespeople,performances'
pg_dump … -s --format 'custom'

# Dump users and groups to file
pg_dumpall -h 'host.fqnd' -p '5432' -U 'postgres' -l 'postgres' -W --roles-only --file 'roles.sql'
pg_dumpall -h 'host.fqnd' -p '5432' -U 'postgres' -l 'postgres' -Wrf 'roles.sql' --no-role-passwords

# Restore backups.
pg_restore -U 'postgres' -d 'sales' 'sales.bak'

# Execute commands from file
# E.g., restore from dump
psql -h 'host.fqnd' -U 'postgres' -d 'postgres' -W -f 'dump.sql' -e

# Generate scram-sha-256 hashes using only tools from PostgreSQL.
# Requires to actually create and delete users.
createuser 'dummyuser' -e --pwprompt && dropuser 'dummyuser'

# Generate scram-sha-256 hashes.
# Leverage https://github.com/supercaracal/scram-sha-256
scram-sha-256 'mySecretPassword'
```

```sql
-- Load extensions from the underlying operating system
-- They must be already installed on the instance
ALTER SYSTEM SET shared_preload_libraries = 'anon';
ALTER DATABASE postgres SET session_preload_libraries = 'anon';
```

</details>

## Functions

Refer [CREATE FUNCTION].

```sql
CREATE OR REPLACE FUNCTION just_return_1() RETURNS integer
LANGUAGE SQL
RETURN 1;

SELECT just_return_1();
```

```sql
CREATE OR REPLACE FUNCTION increment(i integer) RETURNS integer
AS $$
  BEGIN
    RETURN i + 1;
  END;
$$
LANGUAGE plpgsql;
```

```sql
CREATE OR REPLACE FUNCTION entries_in_column(
  table_name TEXT,
  column_name TEXT
) RETURNS INTEGER
LANGUAGE plpgsql
AS $func$
  DECLARE result INTEGER;
  BEGIN
    EXECUTE format('SELECT count(%s) FROM %s LIMIT 2', column_name, table_name) INTO result;
    RETURN result;
  END;
$func$;
SELECT * FROM entries_in_column('vendors','vendor_id');
```

## Extensions of interest

### PostGIS

TODO

### `postgresql_anonymizer`

Extension to mask or replace personally identifiable information or other sensitive data in a DB.

Refer [`postgresql_anonymizer`][postgresql_anonymizer] and [An In-Depth Guide to Postgres Data Masking with Anonymizer].

Admins declare masking rules using the PostgreSQL Data Definition Language (DDL) and specify the anonymization strategy
inside each tables' definition.

<details>
  <summary>Example</summary>

```sh
docker run --rm -d -e 'POSTGRES_PASSWORD=postgres' -p '6543:5432' 'registry.gitlab.com/dalibo/postgresql_anonymizer'
psql -h 'localhost' -p '6543' -U 'postgres' -d 'postgres' -W
```

```sql
=# SELECT * FROM people LIMIT 1;
 id | firstname | lastname |   phone
----+-----------+----------+------------
 T1 | Sarah     | Conor    | 0609110911

-- 1. Activate the dynamic masking engine
=# CREATE EXTENSION IF NOT EXISTS anon CASCADE;
=# SELECT anon.start_dynamic_masking();

-- 2. Declare a masked user
=# CREATE ROLE skynet LOGIN PASSWORD 'skynet';
=# SECURITY LABEL FOR anon ON ROLE skynet IS 'MASKED';

-- 3. Declare masking rules
=# SECURITY LABEL FOR anon ON COLUMN people.lastname IS 'MASKED WITH FUNCTION anon.fake_last_name()';
=# SECURITY LABEL FOR anon ON COLUMN people.phone IS 'MASKED WITH FUNCTION anon.partial(phone,2,$$******$$,2)';

-- 4. Connect with the masked user and test masking
=# \connect - skynet
=# SELECT * FROM people LIMIT 1;
 id | firstname | lastname |   phone
----+-----------+----------+------------
 T1 | Sarah     | Morris   | 06******11
```

</details>

## Further readings

- [SQL]
- [Docker image]
- [Bidirectional replication in PostgreSQL using pglogical]
- [What is the pg_dump command for backing up a PostgreSQL database?]
- [How to SCRAM in Postgres with pgBouncer]
- [`postgresql_anonymizer`][postgresql_anonymizer]
- [pgxn-manager]
- [dverite/postgresql-functions]
- [MySQL]
- [pg_flo]
- [pgAdmin]

### Sources

- [psql]
- [pg_settings]
- [Connect to a PostgreSQL database]
- [Database connection control functions]
- [The password file]
- [How to Generate SCRAM-SHA-256 to Create Postgres 13 User]
- [PostgreSQL: Get member roles and permissions]
- [An In-Depth Guide to Postgres Data Masking with Anonymizer]
- [Get count of records affected by INSERT or UPDATE in PostgreSQL]
- [How to write update function (stored procedure) in Postgresql?]
- [How to search a specific value in all tables (PostgreSQL)?]
- [PostgreSQL: Show all the privileges for a concrete user]
- [PostgreSQL - disabling constraints]
- [Hashing a String to a Numeric Value in PostgreSQL]
- [I replaced my entire tech stack with Postgres...]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[mysql]: mysql.md
[pg_flo]: pg_flo.md
[pgadmin]: pgadmin.md
[sql]: sql.md

<!-- Upstream -->
[create function]: https://www.postgresql.org/docs/current/sql-createfunction.html
[database connection control functions]: https://www.postgresql.org/docs/current/libpq-connect.html
[docker image]: https://github.com/docker-library/docs/blob/master/postgres/README.md
[pg_settings]: https://www.postgresql.org/docs/current/view-pg-settings.html
[psql]: https://www.postgresql.org/docs/current/app-psql.html
[the password file]: https://www.postgresql.org/docs/current/libpq-pgpass.html

<!-- Others -->
[an in-depth guide to postgres data masking with anonymizer]: https://thelinuxcode.com/postgresql-anonymizer-data-masking/
[bidirectional replication in postgresql using pglogical]: https://www.jamesarmes.com/2023/03/bidirectional-replication-postgresql-pglogical.html
[connect to a postgresql database]: https://www.postgresqltutorial.com/connect-to-postgresql-database/
[dverite/postgresql-functions]: https://github.com/dverite/postgresql-functions
[get count of records affected by insert or update in postgresql]: https://stackoverflow.com/questions/4038616/get-count-of-records-affected-by-insert-or-update-in-postgresql#78459743
[hashing a string to a numeric value in postgresql]: https://stackoverflow.com/questions/9809381/hashing-a-string-to-a-numeric-value-in-postgresql#69650940
[how to generate scram-sha-256 to create postgres 13 user]: https://stackoverflow.com/questions/68400120/how-to-generate-scram-sha-256-to-create-postgres-13-user
[how to scram in postgres with pgbouncer]: https://www.crunchydata.com/blog/pgbouncer-scram-authentication-postgresql
[how to search a specific value in all tables (postgresql)?]: https://stackoverflow.com/questions/5350088/how-to-search-a-specific-value-in-all-tables-postgresql/23036421#23036421
[how to write update function (stored procedure) in postgresql?]: https://stackoverflow.com/questions/21087710/how-to-write-update-function-stored-procedure-in-postgresql
[i replaced my entire tech stack with postgres...]: https://www.youtube.com/watch?v=3JW732GrMdg
[pgxn-manager]: https://github.com/pgxn/pgxn-manager
[postgresql - disabling constraints]: https://stackoverflow.com/questions/2679854/postgresql-disabling-constraints#2681413
[postgresql_anonymizer]: https://postgresql-anonymizer.readthedocs.io/en/stable/
[postgresql: get member roles and permissions]: https://www.cybertec-postgresql.com/en/postgresql-get-member-roles-and-permissions/
[postgresql: show all the privileges for a concrete user]: https://stackoverflow.com/questions/40759177/postgresql-show-all-the-privileges-for-a-concrete-user
[what is the pg_dump command for backing up a postgresql database?]: https://www.linkedin.com/advice/3/what-pgdump-command-backing-up-postgresql-ke2ef
