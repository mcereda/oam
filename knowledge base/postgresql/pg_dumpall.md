# pg_dumpall

> [!caution]
> TODO

Command-line tool for creating backups of entire PostgreSQL clusters, and/or global objects like roles and
tablespaces.<br/>
Consider using [`pg_dump`][pg_dump] to create backups of a single database when nothing else is needed.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

It can dump databases in their entirety, or just specific parts of them such as individual tables or schemas.<br/>
It **can** dump objects like roles, groups, tablespace and others.

It produces sets of SQL statements that can be executed to reproduce the original databases' object definitions and
table data.

Suitable when:

- The databases' size is **less** than 100 GB.<br/>
  It tends to start giving issues for bigger databases.
- One plans to migrate the databases' metadata as well as the table data.
- There is a relatively large number of tables to migrate.

> [!important]
> `pg_dumpall` works better when the database is taken offline, but it **does keep the database available** and will
> **not** prevent users from accessing it.<br/>
> Even with other users accessing the database during the backup process, `pg_dumpall` will **always** produce
> consistent results thanks to ACID properties.

<!-- Uncomment if used
<details>
  <summary>Setup</summary>

```sh
```

</details>
-->

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

- [PostgreSQL]
- [pg_dump]
- [pg_restore]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[pg_dump]: pg_dump.md
[pg_restore]: pg_restore.md
[PostgreSQL]: README.md

<!-- Files -->
<!-- Upstream -->
[Documentation]: https://www.postgresql.org/docs/current/app-pg-dumpall.html

<!-- Others -->
