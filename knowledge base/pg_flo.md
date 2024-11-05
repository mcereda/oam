# `pg_flo`

Move and transform data between PostgreSQL databases using Logical Replication.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

  <details style="padding: 0 0 0 1em">
    <summary>Check requirements</summary>

```sql
sourceDb=> SELECT name,setting FROM pg_settings WHERE name IN ('wal_level','rds.logical_replication');
          name           | setting
-------------------------+---------
 rds.logical_replication | on
 wal_level               | logical
(2 rows)
```

  </details>

```sh
docker pull 'nats' && docker pull 'shayonj/pg_flo'
```

  <details style="padding: 0 0 1em 1em">
    <summary>Configuration file</summary>

[Reference][configuration file reference]

```yaml
# Replicator settings
host: "localhost"
port: 5432
dbname: "myapp"
user: "replicator"
password: "secret"
group: "users"
tables:
  - "users"

# Worker settings (postgres sink)
target-host: "dest-db"
target-dbname: "myapp"
target-user: "writer"
target-password: "secret"

# Common settings
nats-url: "nats://localhost:4222"
```

  </details>

</details>

<details>
  <summary>Usage</summary>

```sh
# Start NATS server
docker run -d --name 'pg_flo_nats' --network 'host' -v "$PWD/config/nats-server.conf:/etc/nats/nats-server.conf" \
  'nats' -c '/etc/nats/nats-server.conf'

# Start replicator (using config file)
docker run -d --name 'pg_flo_replicator' --network 'host' -v "$PWD/config/pg_flo.yaml:/etc/pg_flo/config.yaml" \
  'shayonj/pg_flo' replicator --config '/etc/pg_flo/config.yaml'

# Start worker
docker run -d --name 'pg_flo_worker' --network 'host' -v "$PWD/config/pg_flo.yaml:/etc/pg_flo/config.yaml" \
  'shayonj/pg_flo' worker postgres --config '/etc/pg_flo/config.yaml'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Main repository]
- [Transformation rules]

### Sources

- [How to set the wal_level in AWS RDS Postgresql?]
- [Configuration file reference]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[configuration file reference]: https://github.com/shayonj/pg_flo/blob/main/internal/pg-flo.yaml
[main repository]: https://github.com/shayonj/pg_flo
[transformation rules]: https://github.com/shayonj/pg_flo/blob/main/pkg/rules/README.md
[website]: https://www.pgflo.io/

<!-- Others -->
[How to set the wal_level in AWS RDS Postgresql?]: https://dba.stackexchange.com/questions/238686/how-to-set-the-wal-level-in-aws-rds-postgresql#243576
