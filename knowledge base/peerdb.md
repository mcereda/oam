# PeerDB

Fast, simple, and cost effective Postgres replication.

1. [TL;DR](#tldr)
1. [Peers](#peers)
1. [Mirrors](#mirrors)
1. [Alerts](#alerts)
1. [Gotchas](#gotchas)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Glossary</summary>

| Term   | Summary                                                                   |
| ------ | ------------------------------------------------------------------------- |
| Peer   | Connection to a database that PeerDB can query                            |
| Mirror | Stream of changes, feed in real-time, from a source peer to a target peer |
| Alert  | Notifications about issues in flows                                       |

</details>

<details>
  <summary>Setup</summary>

```sh
git clone 'https://github.com/PeerDB-io/peerdb.git' \
&& docker compose -f 'peerdb/docker-compose.yml' up -d
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Connect in SQL mode.
psql 'host=localhost port=9900 password=peerdb'
psql 'postgresql://peerdb.example.org:9900/?password=peerdb'

# Use the REST APIs.
curl -fsS --url 'http://localhost:3000/api/v1/peers/list' --request 'GET' \
  --header "Authorization: Basic $(printf '%s' ':' 'your password here' | base64)"
curl -fsS --url 'http://localhost:3000/api/v1/peers/create' --request 'POST' \
  --header "Authorization: Basic $(printf '%s' ':' 'your password here' | base64)" \
  --header 'Content-Type: application/json' \
  --data '{ … }'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# List peers.
psql "host=localhost port=9900 password=$(gopass show -o 'peerdb/instance')" -c "SELECT id, name, type FROM peers;"
curl -fsS --url 'http://localhost:3000/api/v1/peers/list' \
  -H "Authorization: Basic $(gopass show -o 'peerdb/instance' | xargs printf '%s' ':' | base64)"
```

</details>

## Peers

Peers are connection settings to databases that PeerDB can operate upon.

_Source_ PostgreSQL peers **require** logical replication to be enabled.

<details style="padding: 0 0 1rem 1rem">

```sql
-- Check settings
sourceDb=> SELECT name,setting FROM pg_settings WHERE name IN ('wal_level','rds.logical_replication');
          name           | setting
-------------------------+---------
 rds.logical_replication | on
 wal_level               | logical
(2 rows)
```

```sql
-- Configure sources
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_wal_senders = 10;
ALTER SYSTEM SET max_replication_slots = 10;
```

</details>

Operations:

<details style="padding: 0 0 0 1rem">
  <summary>List</summary>

```sql
SELECT id, name, type FROM peers;
```

```plaintext
GET /api/v1/peers/list
```

</details>

<details style="padding: 0 0 0 1rem">
  <summary>Create or update</summary>

```sql
CREATE PEER IF NOT EXISTS some_postgresql_peer
FROM POSTGRES
WITH (
  host='pg.example.org',
  port='5432',
  database='postgres',
  user='postgres',
  password='password'
);
```

| Peer type  | `peer.type` attribute | Configuration attribute |
| ---------- | --------------------- | ----------------------- |
| ClickHouse | `8`                   | `clickhouse_config`     |
| Kafka      | `9`                   | `kafka_config`          |
| PostgreSQL | `3` or `'POSTGRES'`   | `postgres_config`       |

> The optional `"allow_update": true` attribute in the API seems to do **absolutely nothing** as of the time of writing.

```plaintext
POST /api/v1/peers/create
{
  "allow_update": true,
  "peer": {
    "name": "some_postgresql_peer",
    "type": "POSTGRES",
    "postgres_config": {
      "host": "pg.example.org",
      "port": "5432",
      "database": "postgres",
      "user": "postgres",
      "password": "password"
    }
  }
}
```

</details>

<details style="padding: 0 0 0 1rem">
  <summary>Delete</summary>

```sql
DELETE FROM peers WHERE name == 'some_postgresql_peer';
```

</details>

## Mirrors

Mirrors can be in the following states:

| State      | Returned string     | Description                                                                                           |
| ---------- | ------------------- | ----------------------------------------------------------------------------------------------------- |
| Setup      | `STATUS_SETUP`      | The mirror is creating the target tables and metadata tables                                          |
| Snapshot   | `STATUS_SNAPSHOT`   | The mirror is currently performing the initial snapshot of the tables defined in the mapping          |
| Running    | `STATUS_RUNNING`    | The mirror has completed the initial snapshot, and is in its CDC phase                                |
| Pausing    | `STATUS_PAUSING`    | The mirror is in its CDC phase, and is in the process of pausing                                      |
| Paused     | `STATUS_PAUSED`     | The mirror is in its CDC phase, and is paused                                                         |
| Terminated | `STATUS_TERMINATED` | The mirror has been deleted/terminated                                                                |
| Unknown    | `STATUS_UNKNOWN`    | The mirror is not found in PeerDB's catalog, or its status cannot be obtained due to some other issue |

Mirrors using _PostgreSQL_ peers as sources create [replication slots] in the source DB to get changes from.

Operations:

<details style="padding: 0 0 0 1rem">
  <summary>List</summary>

```plaintext
GET /api/v1/mirrors/list
```

</details>

<details style="padding: 0 0 0 1rem">
  <summary>Create</summary>

| Field                                         | Type            | Required | Default              | Notes                                            |
| --------------------------------------------- | --------------- | -------- | -------------------- | ------------------------------------------------ |
| `flow_job_name`                               | string          | yes      |                      | name of the mirror                               |
| `source_name`                                 | string          | yes      |                      | name of the source peer                          |
| `destination_name`                            | string          | yes      |                      | name of the destination peer                     |
| `table_mappings`                              | array           | yes      |                      |                                                  |
| `table_mappings.source_table_identifier`      | string          | yes      |                      | source schema and table                          |
| `table_mappings.destination_table_identifier` | string          | yes      |                      | destination schema and table                     |
| `table_mappings.exclude`                      | list of strings | no       | []                   | columns excluded from the sync                   |
| `table_mappings.columns`                      | list of objects | no       | []                   | ordering setting; for ClickHouse only            |
| `table_mappings.columns.name`                 | string          | yes      |                      | name of the column                               |
| `table_mappings.columns.ordering`             | number          | yes      |                      | rank of the column                               |
| `idle_timeout_seconds`                        | number          | no       | 60                   |                                                  |
| `publication_name`                            | string          | no       |                      | will be created if not provided                  |
| `max_batch_size`                              | number          | no       | 1000000              |                                                  |
| `do_initial_snapshot`                         | boolean         | yes      |                      |                                                  |
| `snapshot_num_rows_per_partition`             | number          | no       | 1000000              | only used for the initial snapshot               |
| `snapshot_max_parallel_workers`               | number          | no       | 4                    | only used for the initial snapshot               |
| `snapshot_num_tables_in_parallel`             | number          | no       | 1                    | only used for the initial snapshot               |
| `resync`                                      | boolean         | no       | false                | the mirror **must be dropped** before re-syncing |
| `initial_snapshot_only`                       | boolean         | no       | false                |                                                  |
| `soft_delete_col_name`                        | string          | no       | `_PEERDB_IS_DELETED` |                                                  |
| `synced_at_col_name`                          | string          | no       | `_PEERDB_SYNCED_AT`  |                                                  |

```sql
CREATE MIRROR IF NOT EXISTS some_cdc_mirror
FROM main_pg TO snowflake_prod  -- FROM source_peer TO target_peer
WITH TABLE MAPPING
(
  public.regions:main_pg.regions,  -- source_schema.table:target_schema.table
  {
    from: public.countries,  -- source_schema.table
    to: main_pg.countries,   -- target_schema.table
    exclude: [ local_name, size, … ]  -- column_1, …, column_N
  },
  …
)
WITH ( do_initial_copy = true );
```

```plaintext
POST /api/v1/flows/cdc/create
{
  "connection_configs": {
    "flow_job_name": "some_cdc_mirror",
    "source_name": "main_pg",
    "destination_name": "snowflake_prod",
    "do_initial_snapshot": true,
    "table_mappings": [
      {
        "source_table_identifier": "public.regions",
        "destination_table_identifier": "main_pg.regions"
      },
      {
        "source_table_identifier": "public.countries",
        "destination_table_identifier": "main_pg.countries",
        "exclude": [
          "local_name",
          "size",
          …
        ]
      },
      …
    ]
  }
}'
```

</details>

<details style="padding: 0 0 0 1rem">
  <summary>Get status</summary>

```plaintext
POST /api/v1/mirrors/status
{
  "flowJobName": "some_cdc_mirror"
}
```

</details>

<details style="padding: 0 0 0 1rem">
  <summary>Show configuration</summary>

```plaintext
POST /api/v1/mirrors/status
{
  "flowJobName": "some_cdc_mirror",
  "includeFlowInfo": true
}
```

</details>

## Alerts

Operations:

<details>
  <summary>Create</summary>

```plaintext
POST /api/v1/alerts/config
{
  "config": {
    "id": -1,
    "service_type": "slack",
    "service_config": "{\"slot_lag_mb_alert_threshold\":15000,\"open_connections_alert_threshold\":20,\"auth_token\":\"xoxb-012345678901-0123456789012-1234ABcdEFGhijKLMnopQRST\",\"channel_ids\":[\"C01K23X4567\"]}",
    "alert_for_mirrors": [
      "some_cdc_mirror",
      "some_other_mirror"
    ]
  }
}
```

</details>

<details>
  <summary>Show configuration</summary>

```plaintext
GET /api/v1/alerts/config
```

</details>

## Gotchas

- The [documentation] is **sorely lacking**.

- The product appears to have **not** been designed with configuration automation via IaC (nor APIs in general) in mind.

- The API proven **un**reliable, **non**-idempotent, or plain did **not** work as described in the [API Reference] as of
  2025-03-19.<br/>
  E.g., the `allow_update: true` data parameter in a request to the `peers/create` endpoint should make the APIs update
  a peer's settings when one with the given name already exists, but the peer just does **not** get updated.

- API responses hide error messages behind a `200 OK` HTTP status code as of 2025-03-19.

  <details style="padding: 0 0 1rem 1rem;">
    <summary>Response example</summary>

  Output of a `ansible.builtin.uri` Ansible task executed against the PeerDB server:

  ```json
  {
    "json": {
      "message": "POSTGRES peer some_pg_peer was invalidated: failed to create connection: failed to connect to `user=me database=testDb`:\n\t172.31.40.46:6005 (dblab.example.org): tls error: server refused TLS connection\n\t172.31.40.46:6005 (dblab.example.org): failed SASL auth: FATAL: password authentication failed for user \"me\" (SQLSTATE 28P01)",
      "status": "FAILED"
    },
    "msg": "OK (426 bytes)",
    "status": 200,
    "url": "http://localhost:3000/api/v1/peers/create",
  }
  ```

  </details>

- PeerDB seems **unable** to connect to peers which `host` parameter is `localhost` or `127.0.0.1`, but **can** connect
  to the IP address of the system running the service (e.g., `192.168.1.10`).<br/>
  This is most likely a Docker-related issue.

  <details style="padding: 0 0 1rem 1rem;">

  ```sh
  $ docker run --rm --name 'postgres' -d -p '10000:5432' -e POSTGRES_PASSWORD='password' 'postgres:15.5'
  1cb9d450f1c1112601022dec4315a4dac7f564ee67760788850e4f61a8b5d8fb

  $ psql 'host=localhost port=10000 user=postgres password=password' -c '\conninfo'
  You are connected to database "postgres" as user "postgres" on host "localhost" (address "127.0.0.1") at port "10000".

  $ psql 'host=192.168.1.10 port=10000 user=postgres password=password' -c '\conninfo'
  You are connected to database "postgres" as user "postgres" on host "192.168.1.10" at port "10000".

  $ psql 'host=localhost port=9900 user=me password=peerdb'
  psql (15.8, server 14)
  Type "help" for help.
  me=> CREATE PEER IF NOT EXISTS some_pg_peer FROM POSTGRES WITH (host='localhost', port='10000', user='postgres', password='password', database='postgres');
  ERROR:  User provided error: ErrorInfo: ERROR, internal_error, failed to create peer: POSTGRES peer some_pg_peer was invalidated: failed to create connection: failed to connect to `user=postgres database=postgres`:
          127.0.0.1:10000 (localhost): dial error: dial tcp 127.0.0.1:10000: connect: connection refused
          [::1]:10000 (localhost): dial error: dial tcp [::1]:10000: connect: cannot assign requested address
          127.0.0.1:10000 (localhost): dial error: dial tcp 127.0.0.1:10000: connect: connection refused
          [::1]:10000 (localhost): dial error: dial tcp [::1]:10000: connect: cannot assign requested address
  me=> CREATE PEER IF NOT EXISTS some_pg_peer FROM POSTGRES WITH (host='192.168.1.10', port='10000', user='postgres', password='password', database='postgres');
  OK
  ```

  </details>

- PostgreSQL peers do **not** accept connection options as of 2025-03-19.<br/>
  This makes it impossible to specify any or override defaults.

  <details style="padding: 0 0 1rem 1rem;">

  The connection string is composed in code.<br/>
  The [data structure specifying its parameters][peers.proto#PostgresConfig] does **not** accept options, **nor**
  explicit connection strings.

  ```go
  // https://github.com/PeerDB-io/peerdb/blob/6a591128908cbd76df8f7e4094ec838fac08dcda/protos/peers.proto#L73
  message PostgresConfig {
    string host = 1;
    uint32 port = 2;
    string user = 3;
    string password = 4 [(peerdb_redacted) = true];
    string database = 5;
    // defaults to _peerdb_internal
    optional string metadata_schema = 7;
    optional SSHConfig ssh_config = 8;
  }
  ```

  </details>

- PostgreSQL peers have issues connecting to DBLab clones as of 2025-03-19.<br/>
  Peers seemingly **require** SSL to connect to them for some reason, or fail the password authentication when given the
  correct credentials.

  <details style="padding: 0 0 1rem 1rem;">

  ```sh
  $ nc -vz dblab.example.org 6005
  Ncat: Version 7.93 ( https://nmap.org/ncat )
  Ncat: Connected to 172.31.40.46:6005.
  Ncat: 0 bytes sent, 0 bytes received in 0.04 seconds.

  $ psql 'postgresql://dblab.example.org:6005/testDb?user=me&password=1q2w3e4r' -c '\conninfo'
  You are connected to database "testDb" as user "me" on host "dblab.example.org" (address "172.31.40.46") at port "6005".

  $ psql 'host=localhost port=9900 password=peerdb'
  psql (15.8, server 14)
  Type "help" for help.

  me=> CREATE PEER IF NOT EXISTS some_pg_peer FROM POSTGRES WITH (host='dblab.example.org', port='6005', user='me', password='1q2w3e4r', database='testDb');
  ERROR:  User provided error: ErrorInfo: ERROR, internal_error, failed to create peer: POSTGRES peer some_pg_peer was invalidated: failed to create connection: failed to connect to `user=me database=testDb`:
          172.31.40.46:6005 (dblab.example.org): tls error: server refused TLS connection
          172.31.40.46:6005 (dblab.example.org): failed SASL auth: FATAL: password authentication failed for user "me" (SQLSTATE 28P01)
  ```

  </details>

- SQL mode is provided by a translation service, which intercepts the `CREATE PEER` (or other resource) command and
  uses it to create the correct resources in the PostgreSQL backend.<br/>
  The translator does **not** expose **all** the resources (e.g., I could find no alert configuration), **nor** allows
  for easy updates (e.g. the peers and mirrors data is encoded).<br/>
  The data for peers and mirrors is encoded in ways that are **not** disclosed in the [documentation].

- Newly created mirrors will start replication right away.<br/>
  Unless explicitly specified in their definition, this usually means taking an initial snapshot of the mapped tables
  from the source peer.

- When in the `snapshot` state, mirrors **cannot** be paused.<br/>
  If stopped (like stopping, restarting, or killing the container), it **will break** and will need to be restarted.

- **Paused** mirrors using PostgreSQL peers as source will **not** consume the logical replication's transaction log,
  which **will** blow up in size (depending on the number of changes made to the source DB).

- When creating alerts through the APIs, the alert's ID in the request's data must be `-1`.<br/>
  This **will** create duplicates.

## Further readings

- [Website]
- [Codebase]
- [Documentation]
- [Blog]
- [PeerDB UI - Deeper Dive: Part 1]

### Sources

- [Public IPs For PeerDB Cloud]
- [API Reference]
- [SQL reference]
- [Replication Slots]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[api reference]: https://docs.peerdb.io/peerdb-api/reference
[blog]: https://blog.peerdb.io/
[codebase]: https://github.com/PeerDB-io/peerdb
[documentation]: https://docs.peerdb.io/
[peerdb ui - deeper dive: part 1]: https://blog.peerdb.io/peerdb-ui-deeper-dive-part-1
[peers.proto#PostgresConfig]: https://github.com/PeerDB-io/peerdb/blob/6a591128908cbd76df8f7e4094ec838fac08dcda/protos/peers.proto#L73
[public ips for peerdb cloud]: https://docs.peerdb.io/peerdb-cloud/ip-table
[sql reference]: https://docs.peerdb.io/sql/reference
[website]: https://www.peerdb.io/

<!-- Others -->
[replication slots]: https://www.postgresql.org/docs/current/logicaldecoding-explanation.html#LOGICALDECODING-REPLICATION-SLOTS
