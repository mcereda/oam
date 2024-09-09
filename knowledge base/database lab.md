# Database Lab

Database Lab Engine is an open-source platform developed by Postgres.ai to create instant, full-size clones of
production databases.<br/>
Use cases of the clones are to test database migrations, optimize SQL, or deploy full-size staging apps.

The website <https://Postgres.ai/> hosts the SaaS version of the Database Lab Engine.

Configuration file examples are available at <https://gitlab.com/postgres-ai/database-lab/-/tree/v3.0.0/configs>.

1. [Engine](#engine)
1. [Clones](#clones)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Engine

Config file in YAML format, at `~/.dblab/engine/configs/server.yml` by default.

Metadata files at `~/.dblab/engine/meta` by default. The metadata folder **must be writable**.

```sh
# Reload the configuration without downtime.
docker exec -it 'dblab_server' kill -SIGHUP 1

# Follow logs.
docker logs --since '1m' -f 'dblab_server'
docker logs --since '2024-05-01' -f 'dblab_server'
docker logs --since '2024-08-01T23:11:35' -f 'dblab_server'
```

Images for the _Standard_ and _Enterprise_ editions are available at
<https://gitlab.com/postgres-ai/se-images/container_registry/>.<br/>
Images for the _Community_ edition are available at <https://gitlab.com/postgres-ai/custom-images>.

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

- [Database Lab Engine configuration reference]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[dblab]: dblab.md

<!-- Files -->
<!-- Upstream -->
[database lab engine configuration reference]: https://postgres.ai/docs/reference-guides/database-lab-engine-configuration-reference
[documentation]: https://postgres.ai/docs/
[main repository]: https://gitlab.com/postgres-ai/database-lab
[website]: https://postgres.ai/

<!-- Others -->
