# pgBackRest

Reliable backup and restore solution for PostgreSQL.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

> [!caution]
> pgBackRest performs **physical** backups, and it requires **file-level** access to the data directory (`$PGDATA`) of
> the target PostgreSQL server.<br/>
> Use `pg_dump` or `pg_dumpall` to create **logical** backups instead.

Prefer installing pgBackRest from a package, instead of building from source.

Configuration files follow a Windows INI-like convention.<br/>
pgBackRest tries to load the configuration file from `/etc/pgbackrest/pgbackrest.conf` first. If no file exists in that
location, it checks `/etc/pgbackrest.conf`.

One can load multiple configuration files by using the `--config` option multiple times, or by specifying the
`--config-include-path` option to include a directory with multiple `.conf` files.<br/>
Each given file must exist, and be valid individually.<br/>
Multiple loaded files are **concatenated** as if they were one big file.

_Stanzas_ define the backup configuration for specific PostgreSQL database clusters.<br/>
They configure where the clusters are located, how they will be backed up, archiving options, and so on.

Each stanza must define the cluster's path, and its host and user if the cluster is remote.<br/>
Stanza-specific settings override any global configuration.

> [!tip]
> Prefer using names that describe the databases contained in the cluster.<br/>
> Stanza names will be used for the clusters' primary and all replicas, so it would be more appropriate to choose a name
> that somehow describes the actual _function_ of the cluster, rather than the local cluster name.

pgBackRest needs to know where the base data directory for any configured PostgreSQL cluster is located.<br/>
Make sure that pg-path is exactly equal to data_directory as reported by PostgreSQL.

pgBackRest stores backups and archives' WAL segments in _repositories_.<br/>
Repositories do support SFTP or object stores like S3, Azure, GCP.

Backing up a _running_ PostgreSQL cluster requires WAL archiving to be enabled.

> [!note]
> At least one WAL segment will be created during the backup process even if no explicit writes are made to the cluster.

pgBackRest _can_ take _most_ of the backup data from a standby instead of the primary, but both the primary and standby
databases are required to perform the backup.<br/>
Standby backups are identical to backups performed on the primary. This is achieved by starting and stopping the backup
on the primary, copying only files that are replicated from the standby, and finally copying the remaining few files
from the primary.<br/>
In this type of backup, logs and statistics from the primary database **will** be included in the backup.

When performing backups, pgBackRest copies file depending on the backup mode.<br/>
By default, it will attempt to perform an _incremental_ backup. Should no _full_ backups exist yet, pgBackRest will
create a full backup instead.

_Full_ backups save the **entire** contents of the database cluster. They do **not** depend on any other files for
consistency.<br/>
The first backup of the database cluster is always a full backup. Force full backups by running the backup command with
the `--type=full` option.<br/>
pgBackRest can always restore full backups directly.

_Differential_ backups save only those database cluster's files that have changed since the last **full** backup.<br/>
Differential backups require less disk space than a full backup, but require the full backup they depend on to be both
available and valid when restoring.<br/>
pgBackRest restores differential backups by copying the files in the chosen differential backup, plus the appropriate
**unchanged** files from the previous full backup.

_Incremental_ backups save only those database cluster's files that have changed since the last backup.<br/>
That last backup can be another incremental backup, a differential backup, or a full backup.<br/>
Incremental backups are generally much smaller than both full and differential backups, but require **all** the backups
they depend on, **and** these dependencies' own dependencies, to be both available and valid when restoring.

pgBackRest expires backups based on retention options. It will also retain archived WALs by default for backups that
have not expired yet.

Backups can be encrypted.<br/>
Encryption is always performed **client-side** even if the repository type supports encryption.

When multiple repositories are configured, pgBackRest will backup to the **highest** priority repository, unless
otherwise specified by the `--repo` option.

During online backups, pgBackRest waits for those WAL segments that are required for backup consistency to be
archived.<br/>
This wait time is governed by the `archive-timeout` option, which defaults to 60 seconds.

By default, pgBackRest will wait for the next regularly scheduled checkpoint before starting a backup.<br/>
Depending on the `checkpoint_timeout` and `checkpoint_segments` settings in PostgreSQL, it may be quite some time before
a checkpoint completes and the backup can begin. Generally, it is best to set `start-fast=y` to start the backup
immediately.

> [!note]
> Setting `start-fast=y` forces a checkpoint.<br/>
> An additional checkpoint should not have a noticeable impact on performance, but on busy production clusters it might
> still be best to enable the option only when needed.

pgBackRest does not come with built-in scheduler. Run it from `cron` or some other scheduling mechanism.

The `restore` command selects by default the **latest** backup available in the **first** repository that contains any
backup.

Replication slots are **not** restored as per recommendation of PostgreSQL.

<details>
  <summary>Setup</summary>

```sh
# Install
brew install 'pgbackrest'

# Validate the configuration
# Give configuration files as option using their *absolute* path, or also use '--config-path'
pgbackrest check
pgbackrest check --config-path "$PWD"
pgbackrest --config-include-path '/opt/homebrew/etc/pgbackrest' check
pgbackrest --config "$PWD/pgBackRest.conf" --log-level-console 'debug' check
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Get help
pgbackrest help
pgbackrest --help

# Show logs on the CLI
pgbackrest … --log-level-console='info'
pgbackrest … --log-level-console 'debug'

# Create stanzas
pgbackrest … --stanza 'prod-app' stanza-create
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Further readings

- [Website]
- [Codebase]

### Sources

- [User guide][user guide rhel]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[Codebase]: https://github.com/pgbackrest/pgbackrest
[User guide rhel]: https://website/docs/
[Website]: https://pgbackrest.org/

<!-- Others -->
