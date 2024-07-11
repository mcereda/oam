# PostgreSQL

1. [TL;DR](#tldr)
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

```sh
# Installation.
brew install 'postgresql@14'
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
```

```sh
# Connect to servers via CLI client.
# If not given:
# - the hostname defaults to 'localhost';
# - the port defaults to '5432';
# - the username defaults to the current user.
psql 'my-db'
psql 'my-db' 'user'
psql 'postgresql://host:5433/my-db?sslmode=require'
psql -U 'username' -d 'my-db' -h 'hostname' -p 'port' -W
psql --host 'host.fqnd' --port '5432' --username 'postgres' --database 'postgres' --password

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

## Further readings

- [Docker image]
- [Bidirectional replication in PostgreSQL using pglogical]
- [What is the pg_dump command for backing up a PostgreSQL database?]
- [How to SCRAM in Postgres with pgBouncer]

### Sources

- [psql]
- [pg_settings]
- [Connect to a PostgreSQL database]
- [The password file]
- [How to Generate SCRAM-SHA-256 to Create Postgres 13 User]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[docker image]: https://github.com/docker-library/docs/blob/master/postgres/README.md
[psql]: https://www.postgresql.org/docs/current/app-psql.html
[pg_settings]: https://www.postgresql.org/docs/current/view-pg-settings.html
[the password file]: https://www.postgresql.org/docs/current/libpq-pgpass.html

<!-- Others -->
[bidirectional replication in postgresql using pglogical]: https://www.jamesarmes.com/2023/03/bidirectional-replication-postgresql-pglogical.html
[connect to a postgresql database]: https://www.postgresqltutorial.com/connect-to-postgresql-database/
[how to generate scram-sha-256 to create postgres 13 user]: https://stackoverflow.com/questions/68400120/how-to-generate-scram-sha-256-to-create-postgres-13-user
[how to scram in postgres with pgbouncer]: https://www.crunchydata.com/blog/pgbouncer-scram-authentication-postgresql
[what is the pg_dump command for backing up a postgresql database?]: https://www.linkedin.com/advice/3/what-pgdump-command-backing-up-postgresql-ke2ef
