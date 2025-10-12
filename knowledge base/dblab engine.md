# DBLab engine

Creates **instant**, **full-size** clones of PostgreSQL databases.<br/>
Mainly used to test database migrations, optimize SQL, or deploy full-size staging apps.

Can be self-hosted.<br/>
The [website] hosts the SaaS version.

1. [TL;DR](#tldr)
1. [Setup](#setup)
   1. [Configure the storage to enable thin cloning](#configure-the-storage-to-enable-thin-cloning)
   1. [Prepare the database data directory](#prepare-the-database-data-directory)
   1. [Launch DBLab server](#launch-dblab-server)
   1. [Clean up](#clean-up)
1. [Automatically full refresh data without downtime](#automatically-full-refresh-data-without-downtime)
1. [Troubleshooting](#troubleshooting)
   1. [Cannot destroy automatic snapshot in the pool](#cannot-destroy-automatic-snapshot-in-the-pool)
   1. [The automatic full refresh fails claiming it cannot find available pools](#the-automatic-full-refresh-fails-claiming-it-cannot-find-available-pools)
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

## Setup

Refer [How to install DBLab manually].

> [!tip]
> Prefer using PostgresAI Console or AWS Marketplace when installing DBLab in _Standard_ or _Enterprise_ Edition.

Requirements:

- [Docker Engine] must be installed, and usable by the user running DBLab.
- One or more extra disks, or partitions, to dedicate to DBLab Engine's data.

  > [!tip]
  > Prefer dedicating extra disks to the data for better performance.<br/>
  > The Engine can use multiple ZFS pools (or LVM volumes) to [automatically full refresh data without downtime].

  <details style='padding: 0 0 1rem 1rem'>

  ```sh
  $ sudo lsblk
  NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
  ...
  nvme0n1     259:0    0    8G  0 disk
  └─nvme0n1p1 259:1    0    8G  0 part /
  nvme1n1     259:2    0   777G  0 disk

  $ export DBLAB_DISK='/dev/nvme1n1'
  ```

  </details>

Procedure:

1. [Configure the storage to enable thin cloning].
1. [Prepare the database data directory].
1. [Launch DBLab server].

### Configure the storage to enable thin cloning

> [!tip]
> [ZFS] is the recommended way to enable thin cloning in Database Lab.
>
> DBLab also supports LVM volumes, but this method:
>
> - Has much less flexible disk space consumption.
> - Risks clones to be destroyed when executing massive maintenance operations on it.
> - Does not work with multiple snapshots, forcing clones to **always** use the _most recent_ version of the data.

<details style='padding: 0 0 0 1rem'>
  <summary>ZFS pool</summary>

1. Install [ZFS].

   ```sh
   sudo apt-get install 'zfsutils-linux'
   ```

1. Create the pool:

   ```sh
   sudo zpool create \
     -O 'compression=on' \
     -O 'atime=off' \
     -O 'recordsize=128k' \
     -O 'logbias=throughput' \
     -m '/var/lib/dblab/dblab_pool' \
     'dblab_pool' \
     "${DBLAB_DISK}"
   ```

   > [!tip]
   > When planning to set `physicalRestore.sync.enabled: true` in DBLab' configuration, consider lowering the value
   > of the `recordsize` option.
   >
   > <details style='padding: 0 0 1rem 1rem'>
   >
   > Using `recordsize=128k` might provide better compression ratio and performance of massive IO-bound operations,
   > like the creation of an index, but worse performance of WAL replay, causing the lag to be higher.<br/>
   > Vice versa, using `recordsize=8k` improves the performance of WAL replay, but lowers the compression ratio and
   > causes longer duration of index creation.
   >
   > </details>

1. Check the creation results:

   ```sh
   $ sudo zfs list
   NAME         USED  AVAIL  REFER  MOUNTPOINT
   dblab_pool   106K  777G    24K  /var/lib/dblab/dblab_pool

   $ sudo lsblk
   NAME      MAJ:MIN  RM  SIZE RO TYPE MOUNTPOINT
   ...
   nvme0n1     259:0    0     8G  0 disk
   └─nvme0n1p1 259:1    0     8G  0 part /
   nvme1n1     259:0    0   777G  0 disk
   ├─nvme1n1p1 259:3    0   777G  0 part
   └─nvme1n1p9 259:4    0     8M  0 part
   ```

</details>

<details style='padding: 0 0 1rem 1rem'>
  <summary>LVM volume</summary>

1. Install LVM2:

   ```sh
   sudo apt-get install -y 'lvm2'
   ```

1. Create an LVM volume:

   ```sh
   # Create Physical Volume and Volume Group
   sudo pvcreate "${DBLAB_DISK}"
   sudo vgcreate 'dblab_vg' "${DBLAB_DISK}"

   # Create Logical Volume and filesystem
   sudo lvcreate -l '10%FREE' -n 'pool_lv' 'dblab_vg'
   sudo mkfs.ext4 '/dev/dblab_vg/pool_lv'

   # Mount Database Lab pool
   sudo mkdir -p '/var/lib/dblab/dblab_vg-pool_lv'
   sudo mount '/dev/dblab_vg/pool_lv' '/var/lib/dblab/dblab_vg-pool_lv'

   # Bootstrap LVM snapshots so they could be used inside Docker containers
   sudo lvcreate --snapshot --extents '10%FREE' --yes --name 'dblab_bootstrap' 'dblab_vg/pool_lv'
   sudo lvremove --yes 'dblab_vg/dblab_bootstrap'
   ```

> [!important]
> The logical volume size must be defined at volume creation time.<br/>
> By default, it is suggested to allocate 10% of the available system memory. If the volume size exceeds the allocated
> memory, the volume will be destroyed and potentially lead to data loss.<br/>
> To prevent volumes from being destroyed, consider enabling the LVM auto-extend feature.

Enable the auto-extend feature by updating the LVM configuration with the following options:

- `snapshot_autoextend_threshold`: auto-extend _snapshot_ volumes when their usage exceed the specified percentage.
- `snapshot_autoextend_percent`: auto-extend _snapshot_ volumes by the specified percentage of the available space
  once their usage exceeds the threshold.

```sh
sudo sed -i 's/snapshot_autoextend_threshold.*/snapshot_autoextend_threshold = 70/g' '/etc/lvm/lvm.conf'
sudo sed -i 's/snapshot_autoextend_percent.*/snapshot_autoextend_percent = 20/g' '/etc/lvm/lvm.conf'
```

</details>

### Prepare the database data directory

The DBLab Engine server needs data to use as source.<br/>
There are 3 options:

- Use a _generated database_ by generating a synthetic database for testing purposes.
- Create a _physical_ copy of an existing database using _physical_ methods such as `pg_basebackup`.<br/>
  See also [PostgreSQL backup].
- Perform a _logical_ copy of an existing database using _logical_ methods like dumping it and restoring the dump in
  the data directory.

<details style='padding: 0 0 0 1rem'>
  <summary>Generated database</summary>

Preferred when one doesn't have an existing database for testing.

1. Generate some synthetic database in the `PGDATA` directory (located at `/var/lib/dblab/dblab_pool/data` by default).
   A simple way of doing this is to use `pgbench`.<br/>
   With scale factor `-s 100`, the database will occupy ~1.4 GiB.

   ```sh
   sudo docker run --detach \
     --name 'dblab_pg_initdb' --label 'dblab_sync' \
     --env 'PGDATA=/var/lib/postgresql/pgdata' --env 'POSTGRES_HOST_AUTH_METHOD=trust' \
     --volume '/var/lib/dblab/dblab_pool/data:/var/lib/postgresql/pgdata' \
     'postgres:15-alpine'
   sudo docker exec -it 'dblab_pg_initdb' psql -U 'postgres' -c 'create database test'
   sudo docker exec -it 'dblab_pg_initdb' pgbench -U 'postgres' -i -s '100' 'test'
   sudo docker stop 'dblab_pg_initdb'
   sudo docker rm 'dblab_pg_initdb'
   ```

1. Copy the contents of the configuration file example `config.example.logical_generic.yml` from the Database Lab
   repository to `~/.dblab/engine/configs/server.yml`.

   ```sh
   mkdir -p "$HOME/.dblab/engine/configs"
   curl -fsSL \
     --url 'https://gitlab.com/postgres-ai/database-lab/-/raw/v4.0.0/engine/configs/config.example.logical_generic.yml' \
     --output "$HOME/.dblab/engine/configs/server.yml"
   ```

1. Edit the following options in the configuration file:

   - Set `server:verificationToken`.<br/>
     It will be used to authorize API requests to the DBLab Engine.
   - Remove the `logicalDump` section completely.
   - Remove the `logicalRestore` section completely.
   - Leave `logicalSnapshot` as is.
   - If the PostgreSQL major version is **not** 17, set the proper image tag version in `databaseContainer:dockerImage`.

</details>

<details style='padding: 0 0 0 1rem'>
  <summary>Physical copy</summary>

TODO

</details>

<details style='padding: 0 0 1rem 1rem'>
  <summary>Logical copy</summary>

Copy the existing database's data to the `/var/lib/dblab/dblab_pool/data` directory on the DBLab server.<br/>
This step also known as _thick cloning_, and it only needs to be completed once.

1. Copy the contents of the configuration file example `config.example.logical_generic.yml` from the Database Lab
   repository to `~/.dblab/engine/configs/server.yml`.

   ```sh
   mkdir -p "$HOME/.dblab/engine/configs"
   curl -fsSL \
     --url 'https://gitlab.com/postgres-ai/database-lab/-/raw/v4.0.0/engine/configs/config.example.logical_generic.yml' \
     --output "$HOME/.dblab/engine/configs/server.yml"
   ```

1. Edit the following options in the configuration file:

   - Set `server:verificationToken`.<br/>
     It will be used to authorize API requests to the DBLab Engine.
   - Set the connection options in `retrieval:spec:logicalDump:options:source:connection`:
     - `host`: database server host
     - `port`: database server port
     - `dbname`: database name to connect to
     - `username`: database user name
     - `password`: database master password.<br/>
       This can be also set as the `PGPASSWORD` environment variable, and passed to the container using the `--env`
       option of `docker run`.
   - If the PostgreSQL major version is **not** 17, set the proper image tag version in `databaseContainer:dockerImage`.

</details>

### Launch DBLab server

```sh
sudo docker run --privileged --detach --restart on-failure \
  --name 'dblab_server' --label 'dblab_control' \
  --publish '127.0.0.1:2345:2345' \
  --volume '/var/run/docker.sock:/var/run/docker.sock' \
  --volume '/var/lib/dblab:/var/lib/dblab/:rshared' \
  --volume "$HOME/.dblab/engine/configs:/home/dblab/configs" \
  --volume "$HOME/.dblab/engine/meta:/home/dblab/meta" \
  --volume "$HOME/.dblab/engine/logs:/home/dblab/logs" \
  --volume '/sys/kernel/debug:/sys/kernel/debug:rw' \
  --volume '/lib/modules:/lib/modules:ro' \
  --volume '/proc:/host_proc:ro' \
  --env 'DOCKER_API_VERSION=1.39' \
  'postgresai/dblab-server:4.0.1'
```

> [!important]
> With `--publish 127.0.0.1:2345:2345`, **only local connections** will be allowed.<br/>
> To allow external connections, prepend proxies like NGINX or Envoy (preferred) or change the parameter to
> `--publish 2345:2345` to listen to all available network interfaces.

### Clean up

```sh
# Stop and remove all Docker containers
sudo docker ps -aq | xargs --no-run-if-empty sudo docker rm -f

# Remove all Docker images
sudo docker images -q | xargs --no-run-if-empty sudo docker rmi

# Clean up the data directory
sudo rm -rf '/var/lib/dblab/dblab_pool/data'/*

# Remove the dump directory
sudo umount '/var/lib/dblab/dblab_pool/dump'
sudo rm -rf '/var/lib/dblab/dblab_pool/dump'

# Start from the beginning by destroying the ZFS storage pool
sudo zpool destroy 'dblab_pool'
```

## Automatically full refresh data without downtime

Refer [Automatic full refresh data from a source].

DBLab Engine can use two or more ZFS pools or LVM logical volumes to perform an automatic full refresh on schedule and
without downtime.

> [!tip]
> Prefer dedicating an entire disk to each pool or logical volume.<br/>
> This avoids overloading a single disk when syncing, and prevents the whole data failing should a disk fail.

## Troubleshooting

### Cannot destroy automatic snapshot in the pool

Error message example:

```plaintext
2025/10/07 09:49:32 cannot destroy automatic snapshot in the pool
```

Root cause: still unknown.

_**Short-term**_ solution: manually delete the ZFS snapshots and restart the Engine.

<details>

1. Decide what snapshots need to be deleted.

   ```sh
   $ zfs list -t 'snapshot'
   NAME                                   USED  AVAIL  REFER  MOUNTPOINT
   dblab_pool_0@snapshot_20250924055533  92.3G      -   266G  -
   dblab_pool_1@snapshot_20250923130042   132G      -   144G  -
   dblab_pool_1@snapshot_20250915224319   142G      -   145G  -
   dblab_pool_1@snapshot_20251002175419  87.5K      -   145G  -
   ```

1. Ensure no clone is using those snapshots.<br/>
   Reset those that do if necessary.
1. Destroy the chosen ZFS snapshots.

   ```sh
   sudo zfs destroy 'dblab_pool_1@snapshot_20250923130042'
   ```

1. Restart the DBLab Engine's container.<br/>
   Needed to make it recognize the snapshots are gone.

   ```sh
   sudo docker container restart 'dblab_server'
   ```

</details>

### The automatic full refresh fails claiming it cannot find available pools

Context: since version 4.0.0, when starting a full refresh, the operation fails with error _cannot find available
pools_.

_**Apparent**_ root cause: the branching feature seems to consider a pool used by clones, even if those clones have
been destroyed.

_**Short-term**_ solution: **recursively** remove the branch's ZFS dataset from the pool that should be used for the
refresh, and restart the Engine.

<details>

1. Ensure no clone is using snapshots on the pool that should be used for the refresh.<br/>
   Reset those that do if necessary.
1. Destroy the branch's ZFS dataset in the pool that should be used for the refresh.

   ```sh
   sudo zfs list
   sudo zfs destroy -rv 'dblab_pool_0/branch/main'
   ```

1. Restart the DBLab Engine's containers.<br/>
   This will make it recognize the pool as available.

   ```sh
   sudo docker container restart 'dblab_server'
   ```

</details>

## Further readings

- [Website]
- [Codebase]
- [PostgreSQL]
- [Documentation]
- [`dblab`][dblab]
- [Extended Docker Images with PostgreSQL for Database Lab]
- [SE Docker Images with PostgreSQL]

### Sources

- [DeepWiki][deepwiki postgres-ai/database-lab-engine]
- [DBLab Engine configuration reference]
- [Installation guide for DBLab Community Edition][how to install dblab manually]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Automatically full refresh data without downtime]: #automatically-full-refresh-data-without-downtime
[Configure the storage to enable thin cloning]: #configure-the-storage-to-enable-thin-cloning
[Launch DBLab server]: #launch-dblab-server
[Prepare the database data directory]: #prepare-the-database-data-directory

<!-- Knowledge base -->
[dblab]: dblab.md
[Docker engine]: docker.md
[PostgreSQL]: postgresql/README.md
[PostgreSQL backup]: postgresql/README.md#backup
[ZFS]: zfs.md

<!-- Files -->
<!-- Upstream -->
[Automatic full refresh data from a source]: https://v2.postgres.ai/docs/dblab-howtos/administration/logical-full-refresh#automatic-full-refresh-data-from-a-source
[Codebase]: https://gitlab.com/postgres-ai/database-lab
[DBLab Engine configuration reference]: https://postgres.ai/docs/reference-guides/database-lab-engine-configuration-reference
[Documentation]: https://postgres.ai/docs/
[Extended Docker Images with PostgreSQL for Database Lab]: https://gitlab.com/postgres-ai/custom-images
[How to install DBLab manually]: https://postgres.ai/docs/how-to-guides/administration/install-dle-manually
[SE Docker Images with PostgreSQL]: https://gitlab.com/postgres-ai/se-images
[Website]: https://postgres.ai/

<!-- Others -->
[DeepWiki postgres-ai/database-lab-engine]: https://deepwiki.com/postgres-ai/database-lab-engine
