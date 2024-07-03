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

```sh
# Installation.
brew install 'postgresql@14'
sudo dnf install 'postgresql' 'postgresql-server'
sudo zypper install 'postgresql15' 'postgresql15-server'
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
[how to scram in postgres with pgbouncer]: https://www.crunchydata.com/blog/pgbouncer-scram-authentication-postgresql
[what is the pg_dump command for backing up a postgresql database?]: https://www.linkedin.com/advice/3/what-pgdump-command-backing-up-postgresql-ke2ef
