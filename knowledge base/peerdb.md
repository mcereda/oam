# PeerDB

Fast, simple, and cost effective Postgres replication.

1. [TL;DR](#tldr)
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
  <summary>Gotchas</summary>

- The [documentation] is **sorely lacking**.

- The product appears to have **not** been designed with configuration automation via IaC (nor APIs in general) in mind.

- The API proven **un**reliable, **non**-idempotent, or plain did **not** work as described in the [API Reference] as of
  2025-03-19.<br/>
  E.g., the `allow_update: true` data parameter in a request to the `peers/create` endpoint should make the APIs update
  a peer's settings when one with the given name already exists, but the peer just does **not** get updated.

- API responses hide error messages behind a `200 OK` HTTP status code as of 2025-03-19.

  <details style="padding: 0 0 1em 1em;">
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

- PeerDB seems unable to connect to peers which `host` parameter is `localhost` or `127.0.0.1`, but can connect to the
  IP address of the system running the service (e.g., `192.168.1.10`).<br/>
  This is most likely a Docker-related issue.

  <details style="padding: 0 0 1em 1em;">

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

  <details style="padding: 0 0 1em 1em;">

  The connection string is composed in code.<br/>
  The [data structure specifying its parameters][peers.proto#PostgresConfig] does **not** accept options, **nor** explicit
  connection strings.

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

  <details style="padding: 0 0 1em 1em;">

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

- When creating alerts through the APIs, the alert's ID in the request's data must be `-1`.<br/>
  This **will** create duplicates.

- SQL mode is provided by a translation service, which intercepts the `CREATE PEER` (or other resource) command and
  uses it to create the correct resources in the PostgreSQL backend.<br/>
  The translator does **not** expose **all** the resources (e.g., I could find no alert configuration), **nor** allows
  for easy updates (e.g. the peers and mirrors data is encoded).<br/>
  The data for peers and mirrors is encoded in ways that are **not** disclosed in the [documentation].

</details>

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

```sql
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_wal_senders = 10;
ALTER SYSTEM SET max_replication_slots = 10;
```

  </details>

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

# Use the APIs.
curl -fsS --url 'http://localhost:3000/api/v1/peers/list' -X 'GET' \
  -H "Authorization: Basic $(printf '%s' ':' 'your password here' | base64)"
```

```sql
-- List peers.
SELECT id, name, type FROM peers;

-- Create peers.
CREATE PEER IF NOT EXISTS some_pg_peer FROM POSTGRES WITH (
  host='some.pg.fqdn',
  port='5432',
  database='postgres',
  user='postgres',
  password='password'
);

-- Delete peers.
DELETE FROM peers WHERE name == 'some_pg_peer';
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

## Further readings

- [Website]
- [Codebase]
- [Documentation]

### Sources

- [Public IPs For PeerDB Cloud]
- [API Reference]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[api reference]: https://docs.peerdb.io/peerdb-api/reference
[codebase]: https://github.com/PeerDB-io/peerdb
[documentation]: https://docs.peerdb.io/
[peers.proto#PostgresConfig]: https://github.com/PeerDB-io/peerdb/blob/6a591128908cbd76df8f7e4094ec838fac08dcda/protos/peers.proto#L73
[public ips for peerdb cloud]: https://docs.peerdb.io/peerdb-cloud/ip-table
[website]: https://www.peerdb.io/

<!-- Others -->
