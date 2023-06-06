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

# Connect to servers via CLI client.
psql --host "${HOSTNAME:-localhost}" --port "${PORT:-5432}" \
  "${DATABASENAME:-root}" "${USERNAME:-root}"
```

## Further readings

- [Docker image]

## Sources

All the references in the [further readings] section, plus the following:

- [Connect to a PostgreSQL database]

<!-- project's references -->
[docker image]: https://github.com/docker-library/docs/blob/master/postgres/README.md

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
<!-- external references -->
[connect to a postgresql database]: https://www.postgresqltutorial.com/connect-to-postgresql-database/
