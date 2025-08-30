# PostgreSQL

1. [TL;DR](#tldr)
1. [Functions](#functions)
1. [Backup](#backup)
1. [Restore](#restore)
1. [Extensions of interest](#extensions-of-interest)
   1. [PostGIS](#postgis)
   1. [`postgresql_anonymizer`](#postgresql_anonymizer)
1. [Make it distributed](#make-it-distributed)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

One can store one's credentials in the `~/.pgpass` file.

<details style='padding: 0 0 1rem 1rem'>

```plaintext
# line format => hostname:port:database:username:password`
# can use wildcards
postgres.lan:5643:postgres:postgres:BananaORama
*:*:sales:elaine:modestPassword
```

> [!important]
> The credentials file's permissions must be `0600`, or it will be ignored.

</details>

Database roles represent **both** users and groups.<br/>
Roles are **distinct** from the OS' users and groups, and are global across the whole installation (there are **no**
DB-specific roles).

Extensions in PostgreSQL are managed **per database**.

Prefer using [pg_dumpall] to create **logical** backups.<br/>
Consider using [pgBackRest] to create **physical** backups.

Consider using the [Percona toolkit] to ease management.

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

Also see [yugabyte/yugabyte-db] for a distributed, PostgreSQL-like DBMS.

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

## Backup

PostgreSQL offers the [`pg_dump`][pg_dump] and [`pg_dumpall`][pg_dumpall] native client utilities to dump databases to
files.<br/>
They produce sets of SQL statements that can be executed to reproduce the original databases' object definitions and
table data.

These utilities are suitable when:

- The databases' size is less than 100 GB.<br/>
  They tend to start giving issues for bigger databases.
- One plans to migrate the databases' metadata as well as the table data.
- There is a relatively large number of tables to migrate.

> [!important]
> These utilities work better when the database is taken offline (but do **not** require it).

Objects like roles, groups, tablespace and others are **not** dumped by `pg_dump`. It also only dumps a **single**
database per execution.<br/>
Use `pg_dumpall` to back up entire clusters and/or global objects like roles and tablespaces.

Dumps can be output as script or archive file formats.<br/>
Script dumps are plain-text files containing the SQL commands that would allow to reconstruct the dumped database to the
state it was in at the time it was saved.

The _custom_ format (`-F='c'`) and the _directory_ format (`-F='d'`) are the most flexible output file formats.<br/>
They allow for selection and reordering of archived items, support parallel restoration, and are compressed by default.

The directory format is the only format that supports parallel dumps.

```sh
# Dump single DBs
pg_dump --host 'host.fqnd' --port '5432' --username 'postgres' --dbname 'postgres' --password
pg_dump -h 'host.fqnd' -p '5432' -U 'admin' -d 'postgres' -W
pg_dump -U 'postgres' -d 'sales' -F 'custom' -f 'sales.bak' --schema-only
pg_dump … -T 'customers,orders' -t 'salespeople,performances'
pg_dump … -s --format 'custom'
pg_dump … -bF'd' --jobs '3'

# Dump DBs' schema only
pg_dump … --schema-only

# Dump only users and groups to file
pg_dumpall … --roles-only --file 'roles.sql'
pg_dumpall … -rf 'roles.sql' --no-role-passwords

# Dump roles and tablespace
pg_dumpall … --globals-only
pg_dumpall … -g --no-role-passwords
```

> [!important]
> Prefer separating command line options from their values via the `=` character than using a space.<br/>
> This prevents confusion and errors.
>
> <details style='padding: 0 0 0 1rem'>
>
> ```diff
>  pg_dumpall --no-publications \
> -  --format d --jobs 4 --exclude-schema archived --exclude-schema bi
> +  --format='d' --jobs=4 --exclude-schema='archived' --exclude-schema='bi'
> ```
>
> </details>

A list of common backup tools can be found in the [PostgreSQL Wiki][wiki], in the [Backup][wiki backup] page.<br/>
See also [dimitri/pgcopydb].<br/>
For the _limited_™ experience accrued until now, the TL;DR is:

- Prefer [pg_dumpall], and eventually [pg_dump], for **logical** backups.<br/>
- Should one have **physical** access to the DB data directory (`$PGDATA`), consider using [pgBackRest] instead.

## Restore

PostgreSQL offers the `pg_restore` native client utility for restoration of databases from **logical** dumps.

Feed script dumps to `psql` to execute the commands in them and restore the data.

One can give archives created with `pg_dump` or `pg_dumpall` in one of the non-plain-text formats in input to
`pg_restore`. It issues the commands necessary to reconstruct the database to the state it was in at the time it was
saved.

The archive files allow `pg_restore` to be _somewhat_ selective about what it restores, or reorder the items prior to
being restored.

The archive files are designed to be portable across architectures.

> [!important]
> Executing a restore on an online database will probably introduce conflicts of some kind.
> It is very much suggested to take the target offline before restoring.

```sh
# Restore dumps
pg_restore … --dbname 'sales' 'sales.dump'
pg_restore … -d 'sales' -Oxj '8' 'sales.dump'
pg_restore … -d 'sales' --clean --if-exists 'sales.dump'

# Skip materialized views during a restore
pg_dump 'database' -Fc 'backup.dump'
pg_restore --list 'backup.dump' | sed -E '/[[:digit:]]+ VIEW/,+1d' > 'no-views.lst'
pg_restore -d 'database' --use-list 'no-views.lst' 'backup.dump'
# Only then, if needed, refresh the dump with the views
pg_restore --list 'backup.dump' | grep -E --after-context=1 '[[:digit:]]+ VIEW' | sed '/--/d' > 'only-views.lst'
pg_restore -d 'database' --use-list 'only-views.lst' 'backup.dump'
```

For the _limited_™ experience accrued until now, the TL;DR is:

- Prefer [pg_restore], and eventually [psql], for restoring **logical** dumps.<br/>
- Use the restore feature of the external tool used for the backup.

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

## Make it distributed

Refer [How to Scale a Single-Server Database: A Guide to Distributed PostgreSQL].<br/>
See also [yugabyte/yugabyte-db].

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
- [How to Scale a Single-Server Database: A Guide to Distributed PostgreSQL]
- [yugabyte/yugabyte-db]
- [Logical Decoding Concepts]
- [dimitri/pgcopydb]

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
- [What does GRANT USAGE ON SCHEMA do exactly?]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[mysql]: ../mysql.md
[Percona toolkit]: ../percona%20toolkit.md
[pg_dump]: pg_dump.md
[pg_dumpall]: pg_dumpall.md
[pg_flo]: pg_flo.md
[pg_restore]: pg_restore.md
[pgadmin]: pgadmin.md
[pgBackRest]: pgbackrest.md
[sql]: ../sql.md

<!-- Upstream -->
[create function]: https://www.postgresql.org/docs/current/sql-createfunction.html
[database connection control functions]: https://www.postgresql.org/docs/current/libpq-connect.html
[docker image]: https://github.com/docker-library/docs/blob/master/postgres/README.md
[logical decoding concepts]: https://www.postgresql.org/docs/current/logicaldecoding-explanation.html
[pg_settings]: https://www.postgresql.org/docs/current/view-pg-settings.html
[psql]: https://www.postgresql.org/docs/current/app-psql.html
[the password file]: https://www.postgresql.org/docs/current/libpq-pgpass.html
[wiki]: https://wiki.postgresql.org/wiki/
[wiki backup]: https://wiki.postgresql.org/wiki/Ecosystem:Backup
[dimitri/pgcopydb]: https://github.com/dimitri/pgcopydb

<!-- Others -->
[an in-depth guide to postgres data masking with anonymizer]: https://thelinuxcode.com/postgresql-anonymizer-data-masking/
[bidirectional replication in postgresql using pglogical]: https://www.jamesarmes.com/2023/03/bidirectional-replication-postgresql-pglogical.html
[connect to a postgresql database]: https://www.postgresqltutorial.com/connect-to-postgresql-database/
[dverite/postgresql-functions]: https://github.com/dverite/postgresql-functions
[get count of records affected by insert or update in postgresql]: https://stackoverflow.com/questions/4038616/get-count-of-records-affected-by-insert-or-update-in-postgresql#78459743
[hashing a string to a numeric value in postgresql]: https://stackoverflow.com/questions/9809381/hashing-a-string-to-a-numeric-value-in-postgresql#69650940
[how to generate scram-sha-256 to create postgres 13 user]: https://stackoverflow.com/questions/68400120/how-to-generate-scram-sha-256-to-create-postgres-13-user
[how to scale a single-server database: a guide to distributed postgresql]: https://www.yugabyte.com/postgresql/distributed-postgresql/
[how to scram in postgres with pgbouncer]: https://www.crunchydata.com/blog/pgbouncer-scram-authentication-postgresql
[how to search a specific value in all tables (postgresql)?]: https://stackoverflow.com/questions/5350088/how-to-search-a-specific-value-in-all-tables-postgresql/23036421#23036421
[how to write update function (stored procedure) in postgresql?]: https://stackoverflow.com/questions/21087710/how-to-write-update-function-stored-procedure-in-postgresql
[i replaced my entire tech stack with postgres...]: https://www.youtube.com/watch?v=3JW732GrMdg
[pgxn-manager]: https://github.com/pgxn/pgxn-manager
[postgresql - disabling constraints]: https://stackoverflow.com/questions/2679854/postgresql-disabling-constraints#2681413
[postgresql_anonymizer]: https://postgresql-anonymizer.readthedocs.io/en/stable/
[postgresql: get member roles and permissions]: https://www.cybertec-postgresql.com/en/postgresql-get-member-roles-and-permissions/
[postgresql: show all the privileges for a concrete user]: https://stackoverflow.com/questions/40759177/postgresql-show-all-the-privileges-for-a-concrete-user
[what does grant usage on schema do exactly?]: https://stackoverflow.com/questions/17338621/what-does-grant-usage-on-schema-do-exactly
[what is the pg_dump command for backing up a postgresql database?]: https://www.linkedin.com/advice/3/what-pgdump-command-backing-up-postgresql-ke2ef
[yugabyte/yugabyte-db]: https://github.com/yugabyte/yugabyte-db
