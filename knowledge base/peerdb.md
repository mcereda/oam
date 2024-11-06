# PeerDB

Fast, simple, and cost effective Postgres replication.

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

```sql
ALTER SYSTEM SET wal_level = logical;
ALTER SYSTEM SET max_wal_senders = 10;
ALTER SYSTEM SET max_replication_slots = 10;
```

  </details>

</details>

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

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
- [Documentation]

### Sources

- [Public IPs For PeerDB Cloud]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[documentation]: https://docs.peerdb.io/
[main repository]: https://github.com/PeerDB-io/peerdb
[website]: https://www.peerdb.io/
[public ips for peerdb cloud]: https://docs.peerdb.io/peerdb-cloud/ip-table

<!-- Others -->
