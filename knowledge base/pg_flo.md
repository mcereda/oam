# `pg_flo`

Move and transform data between PostgreSQL databases using Logical Replication.

1. [TL;DR](#tldr)
1. [How this works](#how-this-works)
   1. [State Management](#state-management)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Leverages PostgreSQL's logical replication system to capture changes and apply transformations and filtrations to the
data before streaming it to the destination.

Decouples the _replicator_ and _worker_ processes using [NATS] as message broker.<br/>
The NATS server **must have JetStream** enabled (`nats-server -js`).

The _replicator_ component captures PostgreSQL changes via logical replication.<br/>
The _worker_ component processes and routes changes through NATS.

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
# Open a shell
# For debugging purposes, mostly
docker run --rm --name 'pg_flo' --network 'host' --entrypoint 'sh' -ti  'shayonj/pg_flo'

# Start the replicator
# Using the config file failed for some reason at the time of writing
docker run --rm --name 'replicator' --network 'host' 'shayonj/pg_flo' \
  replicator \
    --host 'source-db.fqdn' --dbname 'sales' --user 'pgflo' --password '1q2w3e4r' \
    --group 'whatevah' --nats-url 'nats://localhost:4222'

# Start the worker
docker run --rm --name 'pg_flo_worker' --network 'host' 'shayonj/pg_flo' \
  worker stdout --group 'whatevah' --nats-url 'nats://localhost:4222'
docker run … \
  worker postgres --group 'whatevah' --nats-url 'nats://localhost:4222' \
    --target-host 'dest-db.fqdn' --target-dbname 'sales' --target-user 'pgflo' --target-password '1q2w3e4r'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Start a basic replication to stdout as example.
docker run --rm --name 'pg_flo_nats' -p '4222:4222' 'nats' -js \
&& docker run -d --name 'pg_flo_replicator' --network 'host' 'shayonj/pg_flo' \
    replicator \
      --host 'source-db.fqdn' --port '6001' --dbname 'sales' --user 'pgflo' --password '1q2w3e4r' \
      --copy-and-stream --group 'whatevah' --nats-url 'nats://localhost:4222' \
&& docker run -d --name 'pg_flo_worker' --network 'host' 'shayonj/pg_flo' \
    worker stdout --group 'whatevah' --nats-url 'nats://localhost:4222'
```

</details>

## How this works

Refer [How it Works].

1. The _replicator_ creates a PostgreSQL **publication** in the source DB for the replicated tables.
1. The _replicator_ creates a **replication slot** in the source DB.<br/>
   This ensures no data is lost between streaming sessions.
1. The _replicator_ starts streaming changes from the source DB and publishes them to NATS:

   - **After** performing an initial bulk copy, if in _Copy-and-Stream_ mode.

     <details style="margin-top: -1em; padding: 0 0 1em 0">

     If no valid LSN is found in NATS, `pg_flo` performs an initial bulk copy of existing data.

     The process is parallelized for fast data sync:

     1. A snapshot is taken to ensure consistency.
     1. Each table is divided into page ranges.
     1. Multiple workers copy different ranges concurrently.

     </details>

   - **Immediately**, from the last known position, if in _Stream-Only_ mode.

   It also stores the last processed LSN in NATS, allowing the _worker_ to resume operations from where it left off in
   case of interruptions.

1. The _worker_ processes messages from NATS.

   <details style="margin-top: -1em; padding: 0 0 1em 0">

   | Message type                                     | Summary                              |
   | ------------------------------------------------ | ------------------------------------ |
   | Relation                                         | Allow understanding table structures |
   | `Insert`, `Update`, `Delete`                     | Contain actual data changes          |
   | `Begin`, `Commit`                                | Enable transaction boundaries        |
   | DDL changes (e.g. `ALTER TABLE`, `CREATE INDEX`) | Contain actual structural changes    |

   </details>

1. The _worker_ converts received data into a structured format with type-aware conversions for different PostgreSQL
   data types.
1. \[If any rule is configured] The _worker_ applies transformation and filtering rules to the data.

   <details style="margin-top: -1em; padding: 0 0 1em 0">

   Transform Rules:

   - Regex: apply regular expression transformations to string values.
   - Mask: hide sensitive data, keeping the first and last characters visible.

   Filter Rules:

   - Comparison: filter based on equality, inequality, greater than, less than, etc.
   - Contains: filter string values based on whether they contain a specific substring.

   Rules _can_ be applied selectively to `insert`, `update`, or `delete` operations.

   </details>

1. The _worker_ buffers processed data.
1. The _worker_ flushes data periodically from the buffer to the configured _sinks_.<br/>
   Currently, _sinks_ can be `stdout`, files, PostgreSQL DBs or webhooks.<br/>
   Flushed data is written to DB sinks in batches to optimize write operations.

### State Management

The _replicator_ keeps track of its progress by updating the _Last LSN_ in NATS.

The _worker_ maintains its progress to ensure data consistency.<br/>
This allows for resumable operations across multiple runs.

Periodic status updates are sent to the source DB to maintain the replication's connection.

## Further readings

- [Website]
- [Main repository]
- [Transformation rules]
- [NATS]

### Sources

- [How to set the wal_level in AWS RDS Postgresql?]
- [Configuration file reference]
- [How it Works]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[nats]: nats.md

<!-- Files -->
<!-- Upstream -->
[configuration file reference]: https://github.com/shayonj/pg_flo/blob/main/internal/pg-flo.yaml
[how it works]: https://github.com/shayonj/pg_flo/blob/main/internal/how-it-works.md
[main repository]: https://github.com/shayonj/pg_flo
[transformation rules]: https://github.com/shayonj/pg_flo/blob/main/pkg/rules/README.md
[website]: https://www.pgflo.io/

<!-- Others -->
[How to set the wal_level in AWS RDS Postgresql?]: https://dba.stackexchange.com/questions/238686/how-to-set-the-wal-level-in-aws-rds-postgresql#243576
