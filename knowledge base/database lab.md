# Database Lab

Database Lab Engine is an open-source platform developed by Postgres.ai to create instant, full-size clones of
production databases.<br/>
Use cases of the clones are to test database migrations, optimize SQL, or deploy full-size staging apps.

The website <https://Postgres.ai/> hosts the SaaS version of the Database Lab Engine.

1. [Clones](#clones)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Clones

Database clones comes in two flavours:

- _Thick_ cloning: the regular way to copy data.<br/>
  It is also how data is copied to Database Lab the first time a source is added.

  Thick clones can be:

  - _Logical_: do a regular dump and restore using `pg_dump` and `pg_restore`.
  - _Physical_: done using `pg_basebackup` or restoring data from physical archives created by backup tools such as
    WAL-E/WAL-G, Barman, pgBackRest, or pg_probackup.

  > Managed PostgreSQL databases in cloud environments (e.g.: AWS RDS) support only the logical clone type.

  The Engine supports continuous synchronization with the source databases.<br/>
  Achieved by repeating the thick cloning method one initially used for the source.

- _Thin_ cloning: local containerized database clones based on CoW (Copy-on-Write) spin up in few seconds.<br/>
  They share most of the data blocks, but logically they look fully independent.<br/>
  The speed of thin cloning does **not** depend on the database size.

  As of 2024-06, Database Lab Engine supports ZFS and LVM for thin cloning.<br/>
  With ZFS, the Engine periodically creates a new snapshot of the data directory and maintains a set of snapshots. When
  requesting a new clone, users choose which snapshot to use as base.

## Further readings

- [Website]
- [Main repository]
- [Documentation]
- [`dblab`][dblab]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[dblab]: dblab.md

<!-- Files -->
<!-- Upstream -->
[documentation]: https://postgres.ai/docs/
[main repository]: https://gitlab.com/postgres-ai/database-lab
[website]: https://postgres.ai/

<!-- Others -->
