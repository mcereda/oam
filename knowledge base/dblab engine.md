# DBLab engine

Creates **instant**, **full-size** clones of PostgreSQL databases.<br/>
Mainly used to test database migrations, optimize SQL, or deploy full-size staging apps.

Can be self-hosted.<br/>
The [website] hosts the SaaS version.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

It leverages thin clones to provide full-sized database environments in seconds, regardless of the source database's
size.<br/>
It relies on copy-on-write (CoW) filesystem technologies (currently ZFS or LVM) to provide efficient storage and
provisioning for database clones.

Relies on Docker containers to isolate and run PostgreSQL instances for each clone.<br/>
Each clone gets its own network port.

The _Retrieval Service_ acquires data from source PostgreSQL databases and prepares it for cloning.<br/>
It supports:

- **Physical** retrieval, by using physical backup methods like `pg_basebackup`, WAL-G, or `pgBackRest` to copy the
  entire `PGDATA` directory.
- **Logical** retrieval, by using logical dump and restore tools like `pg_dump` and `pg_restore` to copy database
  objects and data.

> [!important]
> Managed PostgreSQL databases in cloud environments (e.g.: AWS RDS) support only logical synchronization.

The _Pool Manager_ manages storage pools and filesystem operations.<br/>
It abstracts the underlying filesystem (ZFS or LVM) and provides a consistent interface for snapshot and clone
operations.<br/>
It supports different pools, each with its own **independent** configuration and filesystem manager.

The _Provisioner_ manages the resources it needs to run and handle the lifecycle of database clones.<br/>
It creates and manages PostgreSQL instances by allocating network ports to them from a pool, creating and managing the
containers they run on, mounting filesystem clones for them to use, and configuring them.

The _Cloning Service_ orchestrates the overall process of creating and managing database clones by coordinating the
Provisioner and Pool Manager to fulfill cloning requests from clients.

The _API Server_ exposes HTTP endpoints for interactions by providing RESTful APIs that allow creating and managing
clones, viewing snapshots, and monitoring systems' status.

Database Lab Engine uses a YAML-based configuration file, which is loaded at startup and **can be reloaded at
runtime**.<br/>
It is located at `~/.dblab/engine/configs/server.yml` by default.

Metadata files are located at `~/.dblab/engine/meta` by default.<br/>
The metadata's folder **must be writable**.

```sh
# Reload the configuration without downtime.
docker exec -it 'dblab_server' kill -SIGHUP 1

# Follow logs.
docker logs --since '1m' -f 'dblab_server'
docker logs --since '2024-05-01' -f 'dblab_server'
docker logs --since '2024-08-01T23:11:35' -f 'dblab_server'
```

Before DLE can create thin clones, it must first obtain a **full** copy of the source database.<br/>
The initial data retrieval process is also referred to as _thick cloning_, and is typically a one-time or a scheduled
operation.

Each clone runs in its own PostgreSQL container, and its configuration can be customized.<br/>
Clone DBs configuration starting point is at `~/.dblab/postgres_conf/postgresql.conf`.

Database clones come as _thick_ or _thin_ clones.

Thick clones work as normal replica would, **continuously** synchronizing with their source database.

Thin clones:

1. Prompt the creation of a dedicated filesystem snapshot.
1. Spin up a local database container that mounts that snapshot as volume.

The creation speed of thin clones does **not** depend on the database's size.

When thin clones are involved, DLE **periodically** creates a new snapshot from the source database, and maintains a
set of them.<br/>
When requesting a new clone, users choose which snapshot to use as its base.

Container images for the _Community_ edition are available at <https://gitlab.com/postgres-ai/custom-images>.<br/>
Specialized images for only the _Standard_ and _Enterprise_ editions are available at
<https://gitlab.com/postgres-ai/se-images/container_registry/>.

## Further readings

- [Website]
- [Codebase]
- [Documentation]
- [`dblab`][dblab]

### Sources

- [DeepWiki][deepwiki postgres-ai/database-lab-engine]
- [Database Lab Engine configuration reference]
- [Installation guide for DBLab Community Edition][how to install dblab manually]

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
[Documentation]: https://postgres.ai/docs/
[how to install dblab manually]: https://postgres.ai/docs/how-to-guides/administration/install-dle-manually
[Codebase]: https://gitlab.com/postgres-ai/database-lab
[Website]: https://postgres.ai/

<!-- Others -->
[DeepWiki postgres-ai/database-lab-engine]: https://deepwiki.com/postgres-ai/database-lab-engine
