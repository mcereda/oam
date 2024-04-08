# PostgreSQL

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

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
psql -U 'username' -d 'my-db' -h 'hostname' -p 'port' -W 'password'

# List available databases.
psql … --list

# Execute commands.
psql 'my-db' … -c 'select * from tableName;' -o 'out.file'
psql 'my-db' … -c 'select * from tableName;' -H
psql 'my-db' … -f 'commands.sql'
```

## Further readings

- [Docker image]

### Sources

- [psql]
- [Connect to a PostgreSQL database]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Upstream -->
[docker image]: https://github.com/docker-library/docs/blob/master/postgres/README.md
[psql]: https://www.postgresql.org/docs/current/app-psql.html

<!-- Others -->
[connect to a postgresql database]: https://www.postgresqltutorial.com/connect-to-postgresql-database/
