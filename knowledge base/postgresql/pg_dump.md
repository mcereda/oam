# pg_dump

> [!caution]
> TODO

Command-line tool for creating backups of a **single** PostgreSQL database.<br/>
Consider using [`pg_dumpall`][pg_dumpall] to create backups of entire clusters, or global objects like roles and
tablespaces.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

It can dump a database in its entirety, or just specific parts of it such as individual tables or schemas.<br/>
It does **not** dump objects like roles, groups, tablespace and others. Consider using [`pg_dumpall`][pg_dumpall] for
those.

It produces sets of SQL statements that can be executed to reproduce the original databases' object definitions and
table data.

Suitable when:

- The database' size is **less** than 100 GB.<br/>
  It tends to start giving issues for bigger databases.
- One plans to migrate the database' metadata as well as the table data.
- There is a relatively large number of tables to migrate.

> [!important]
> `pg_dump` works better when the database is taken offline, but it **does keep the database available** and will
> **not** prevent users from accessing it.<br/>
> Even with other users accessing the database during the backup process, `pg_dump` will **always** produce consistent
> results thanks to ACID properties.

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
- [pg_dumpall]
- [pg_restore]

### Sources

- [Documentation]
- [A Complete Guide to pg_dump With Examples, Tips, and Tricks]
- [How to speed up pg_dump when dumping large databases]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[pg_dumpall]: pg_dumpall.md
[pg_restore]: pg_restore.md
[PostgreSQL]: README.md

<!-- Files -->
<!-- Upstream -->
[Documentation]: https://www.postgresql.org/docs/current/app-pgdump.html

<!-- Others -->
[A Complete Guide to pg_dump With Examples, Tips, and Tricks]: https://www.dbvis.com/thetable/a-complete-guide-to-pg-dump-with-examples-tips-and-tricks/
[How to speed up pg_dump when dumping large databases]: https://postgres.ai/docs/postgres-howtos/database-administration/backup-recovery/how-to-speed-up-pg-dump
