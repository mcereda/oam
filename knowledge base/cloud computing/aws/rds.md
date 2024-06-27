# Amazon Relational Database Service

1. [TL;DR](#tldr)
1. [Storage](#storage)
1. [Parameter Groups](#parameter-groups)
1. [Option Groups](#option-groups)
1. [Backup](#backup)
   1. [Automatic backups](#automatic-backups)
   1. [Manual backups](#manual-backups)
   1. [Export snapshots to S3](#export-snapshots-to-s3)
1. [Restore](#restore)
1. [Encryption](#encryption)
1. [Operations](#operations)
   1. [PostgreSQL](#postgresql)
      1. [Reduce allocated storage by migrating using transportable databases](#reduce-allocated-storage-by-migrating-using-transportable-databases)
1. [Troubleshooting](#troubleshooting)
   1. [ERROR: extension must be loaded via shared\_preload\_libraries](#error-extension-must-be-loaded-via-shared_preload_libraries)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

<details>
  <summary>CLI usage</summary>

```sh
# Show RDS instances.
aws rds describe-db-instances
aws rds describe-db-instances --output 'json' --query "DBInstances[?(DBInstanceIdentifier=='master-prod')]"

# Show Parameter Groups.
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15'

# Create parameter Groups.
aws rds create-db-parameter-group --db-parameter-group-name 'pg15-source-transport-group' \
  --db-parameter-group-family 'postgres15' --description 'Parameter group with transport parameters enabled'

# Modify Parameter Groups.
aws rds modify-db-parameter-group --db-parameter-group-name 'pg15-source-transport-group' \
  --parameters \
    'ParameterName=pg_transport.num_workers,ParameterValue=4,ApplyMethod=pending-reboot' \
    'ParameterName=pg_transport.timing,ParameterValue=1,ApplyMethod=pending-reboot' \
    'ParameterName=pg_transport.work_mem,ParameterValue=131072,ApplyMethod=pending-reboot' \
    'ParameterName=shared_preload_libraries,ParameterValue="pg_stat_statements,pg_transport",ApplyMethod=pending-reboot' \
    'ParameterName=max_worker_processes,ParameterValue=24,ApplyMethod=pending-reboot'

# Restore instances from snapshots.
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier 'myNewBbInstance' \
  --db-snapshot-identifier 'myOldDbSnapshot'

# Start export tasks.
aws rds start-export-task \
  --export-task-identifier 'db-finalSnapshot-2024' \
  --source-arn 'arn:aws:rds:eu-west-1:012345678901:snapshot:db-prod-final-2024' \
  --s3-bucket-name 'backups' \
  --iam-role-arn 'arn:aws:iam::012345678901:role/CustomRdsS3Exporter' \
  --kms-key-id 'arn:aws:kms:eu-west-1:012345678901:key/abcdef01-2345-6789-abcd-ef0123456789'

# Get export tasks' status.
aws rds describe-export-tasks
aws rds describe-export-tasks --export-task-identifier 'my-snapshot-export'

# Cancel tasks.
aws rds cancel-export-task --export-task-identifier 'my_export'
```

</details>
<br/>

Read replicas **can** be promoted to standalone DB instances.<br/>
See [Working with DB instance read replicas].

Disk free metrics are available in CloudWatch.

One can choose any of the following retention periods for instances' Performance Insights data:

- 7 days (default, free tier).
- _n_ months, where n is a number from 1 to 24.<br/>
  In CLI and IaC, this number must be _n*31_.

## Storage

Refer [Amazon RDS DB instance storage].

When selecting General Purpose SSD or Provisioned IOPS SSD, RDS automatically stripes storage across multiple volumes to
enhance performance depending on the engine selected and the amount of storage requested:

| DB engine                        | Storage size      | Number of volumes provisioned |
| -------------------------------- | ----------------- | ----------------------------- |
| Db2                              | Less than 400 GiB | 1                             |
| Db2                              | 400 to 65,536 GiB | 4                             |
| MariaDB<br/>MySQL<br/>PostgreSQL | Less than 400 GiB | 1                             |
| MariaDB<br/>MySQL<br/>PostgreSQL | 400 to 65,536 GiB | 4                             |
| Oracle                           | Less than 200 GiB | 1                             |
| Oracle                           | 200 to 65,536 GiB | 4                             |
| SQL Server                       | Any               | 1                             |

When modifying a General Purpose SSD or Provisioned IOPS SSD volume, it goes through a sequence of states.<br/>
While the volume is in the `optimizing` state, volume performance is between the source and target configuration
specifications.<br/>
Transitional volume performance will be no less than the **lower** of the two specifications.

When increasing allocated storage, increases must be by at least of 10%. Trying to increase the value by less than 10%
will result in an error.<br/>
The allocated storage **cannot** be increased when restoring RDS for SQL Server DB instances.

> The allocated storage size of any DB instance **cannot be lowered** after creation.

Decrease the storage size of DB instances by creating a new instance with lower provisioned storage size, then migrate
the data into the new instance.<br/>
Use one of the following methods:

- Use the database engine's native dump and restore method.
  This **will** require **long** downtime.
- Consider using [transportable DBs][migrating databases using rds postgresql transportable databases] when dealing with
  PostgreSQL DBs should the requirements match.<br/>
  This **will** require **_some_** downtime.
- [Perform an homogeneous data migration][migrating databases to their amazon rds equivalents with aws dms] using AWS's
  [DMS][what is aws database migration service?]<br/>
  This **should** require **minimal** downtime.

## Parameter Groups

Refer [Working with parameter groups].

Used to specify how a DB is configured.

Learn about available parameters by describing the existing default ones:

```sh
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15'
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15' \
  --query "Parameters[?ParameterName=='shared_preload_libraries']" --output 'table'
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15' \
  --query "Parameters[?ParameterName=='shared_preload_libraries'].ApplyMethod" --output 'text'
```

## Option Groups

Used to enable and configure additional features and functionalities in a DB.

## Backup

RDS backup storage for each Region is calculated from both the automated backups and manual DB snapshots for that
Region.<br/>
Moving snapshots to other Regions increases the backup storage in the destination Regions.

Backups are stored in [S3].

Should one choose to retain automated backups when deleting DB instances, those backups are saved for the full retention
period; otherwise, all automated backups are deleted with the instance.<br/>
After automated backups are deleted, they **cannot** be recovered.

Should one choose to have RDS create a final DB snapshot before deleting a DB instance, one can use that or previously
created manual snapshots to recover it.

### Automatic backups

Automatic backups are storage volume snapshots of **entire** DB instances.

Automatic backups are **enabled** by default.<br/>
Setting the backup retention period to 0 disables them, setting it to a nonzero value (re)enables them.

> Enabling automatic backups takes the affected instances offline to have a backup created immediately.<br/>
> It **will** cause outages.

Automatic backups occur **daily** during the instances' backup window, configured in 30 minute periods. Should backups
require more time than allotted to the backup window, they will continue after the window ends and until they finish.

Backups are retained for up to 35 days (_backup retention period_).<br/>
One can recover DB instances to any point in time from the backup retention period.

The backup window can't overlap with the weekly maintenance window for DB instance or Multi-AZ DB cluster.<br/>
During automatic backup windows storage I/O might be suspended briefly while the backup process initializes.
Initialization typically takes up to a few seconds. One might also experience elevated latencies for a few minutes
during backups for Multi-AZ deployments.<br/>
For MariaDB, MySQL, Oracle and PostgreSQL Multi-AZ deployments, I/O activity isn't suspended on the primary instance as
the backup is taken from the standby.<br/>
Automated backups might occasionally be skipped if instances or clusters are running heavy workloads at the time backups
are supposed to start.

DB instances must be in the `available` state for automated backups to occur.<br/>
Automated backups don't occur while DB instances are in other states (i.e., `storage_full`).

Automated backups aren't created while a DB instance or cluster is stopped.<br/>
RDS doesn't include time spent in the stopped state when the backup retention window is calculated. This means backups
can be retained longer than the backup retention period if a DB instance has been stopped.

Automated backups don't occur while a DB snapshot copy is running in the same AWS Region for the same database.

### Manual backups

Back up DB instances manually by creating DB snapshots.<br/>
The first snapshot contains the data for the full database. Subsequent snapshots of the same database are incremental.

One can copy both automatic and manual DB snapshots, but only share manual DB snapshots.

Manual snapshots **never** expire and are retained indefinitely.

One can store up to 100 manual snapshots per Region.

### Export snapshots to S3

One can export DB snapshot data to [S3] buckets.<br/>
RDS spins up an instance from the snapshot, extracts data from it and stores the data in Apache Parquet format.<br/>
By default **all** data in the snapshots is exported, but one can specify specific sets of databases, schemas, or tables
to export.

- The export process runs in the background and does **not** affect the performance of active DB instances.
- Multiple export tasks for the same DB snapshot cannot run simultaneously. This applies to both full and partial
  exports.
- Exporting snapshots from DB instances that use magnetic storage isn't supported.
- The following characters aren't supported in table column names:

  ```plaintext
  , ; { } ( ) \n \t = (space) /
  ```

  Tables containing those characters in column names are skipped during export.
- PostgreSQL _temporary_ and _unlogged_ tables are skipped during export.
- Large objects in the data, like BLOBs or CLOBs, close to or greater than 500 MB will make the export fail.
- Large rows close to or greater than 2 GB will make their table being skipped during export.
- Data exported from snapshots to S3 cannot be restored to new DB instances.
- The snapshot export tasks require a role with write-access permission to the destination S3 bucket:

  ```json
  {
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "export.rds.amazonaws.com"
        }
    }]
  }
  ```

  ```json
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
          "s3:PutObject*",
          "s3:ListBucket",
          "s3:GetObject*",
          "s3:DeleteObject*",
          "s3:GetBucketLocation"
      ],
      "Resource": [
          "arn:aws:s3:::bucket",
          "arn:aws:s3:::bucket/*"
      ]
    }]
  }
  ```

After the export, one can analyze the data directly through
[Athena](https://docs.aws.amazon.com/athena/latest/ug/parquet-serde.html) or
[Redshift Spectrum](https://docs.aws.amazon.com/redshift/latest/dg/copy-usage_notes-copy-from-columnar.html).

<details>
  <summary>In the Console</summary>

The _Export to Amazon S3_ console option appears only for snapshots that can be exported to Amazon S3.<br/>
Snapshots might not be available for export because of the following reasons:

- The DB engine isn't supported for S3 export.
- The DB instance version isn't supported for S3 export.
- S3 export isn't supported in the AWS Region where the snapshot was created.

</details>
<details>
  <summary>Using the CLI</summary>

```sh
# Start new tasks.
$ aws rds start-export-task \
  --export-task-identifier 'db-finalSnapshot-2024' \
  --source-arn 'arn:aws:rds:eu-west-1:012345678901:snapshot:db-prod-final-2024' \
  --s3-bucket-name 'backups' --s3-prefix 'rds' \
  --iam-role-arn 'arn:aws:iam::012345678901:role/CustomRdsS3Exporter' \
  --kms-key-id 'arn:aws:kms:eu-west-1:012345678901:key/abcdef01-2345-6789-abcd-ef0123456789'
{
  "ExportTaskIdentifier": "db-finalSnapshot-2024",
  "IamRoleArn": "arn:aws:iam::012345678901:role/CustomRdsS3Exporter",
  "KmsKeyId": "arn:aws:kms:eu-west-1:012345678901:key/abcdef01-2345-6789-abcd-ef0123456789",
  "PercentProgress": 0,
  "S3Bucket": "backups",
  "S3Prefix": "rds",
  "SnapshotTime": "2024-06-17T09:04:41.387000+00:00",
  "SourceArn": "arn:aws:rds:eu-west-1:012345678901:snapshot:db-prod-final-2024",
  "Status": "STARTING",
  "TotalExtractedDataInGB": 0
}

# Get tasks' status.
$ aws rds describe-export-tasks
$ aws rds describe-export-tasks --export-task-identifier 'db-finalSnapshot-2024'
$ aws rds describe-export-tasks --query 'ExportTasks[].WarningMessage' --output 'yaml'

# Cancel tasks.
$ aws rds cancel-export-task --export-task-identifier 'my_export'
{
    "Status": "CANCELING",
    "S3Prefix": "",
    "ExportTime": "2019-08-12T01:23:53.109Z",
    "S3Bucket": "DOC-EXAMPLE-BUCKET",
    "PercentProgress": 0,
    "KmsKeyId": "arn:aws:kms:AWS_Region:123456789012:key/K7MDENG/bPxRfiCYEXAMPLEKEY",
    "ExportTaskIdentifier": "my_export",
    "IamRoleArn": "arn:aws:iam::123456789012:role/export-to-s3",
    "TotalExtractedDataInGB": 0,
    "TaskStartTime": "2019-11-13T19:46:00.173Z",
    "SourceArn": "arn:aws:rds:AWS_Region:123456789012:snapshot:export-example-1"
}
```

</details>

## Restore

DB instances **can** be restored from DB snapshots.<br/>
Restoring instances from snapshots requires the new instances to have **equal or more** allocated storage than what the
original instance had allocated at the time the snapshot was taken.

```sh
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier 'myNewDbInstance' \
  --db-snapshot-identifier 'myDbSnapshot'
```

## Encryption

RDS automatically integrates with AWS KMS for key management.

By default, RDS uses the RDS AWS managed key (`aws/rds`) for encryption.<br/>
This key can't be managed, rotated, nor deleted by users.

RDS will automatically put databases into a terminal state when access to the KMS key is required but the key has been
disabled or deleted, or its permissions have been somehow revoked.<br/>
This change could be immediate or deferred depending on the use case that required access to the KMS key.<br/>
In this terminal state, DB instances are no longer available and their databases' current state can't be recovered. To
restore DB instances, one must first re-enable access to the KMS key for RDS, and then restore the instances from their
latest available backup.

## Operations

### PostgreSQL

#### Reduce allocated storage by migrating using transportable databases

Refer [Migrating databases using RDS PostgreSQL Transportable Databases],
[Transporting PostgreSQL databases between DB instances] and
[Transport PostgreSQL databases between two Amazon RDS DB instances using pg_transport].

> When the transport begins, all current sessions on the **source** database are ended and the DB is put in ReadOnly
> mode.<br/>
> Only the specific source database that is being transported is affected. Others are **not** affected.
>
> The in-transit database will be **inaccessible** on the **target** DB instance for the duration of the transport.<br/>
> During transport, the target DB instance **cannot be restored** to a point in time, as the transport is **not**
> transactional and does **not** use the PostgreSQL write-ahead log to record changes.

A test transfer of a ~350 GB database between two `db.t4g.medium` instances using gp3 storage took FIXME minutes.

<details>
  <summary>Requirements</summary>

- A **source** DB to copy from.
- A **target** instance to copy the DB to.

  > Since the transport will create the DB on the target, the target instance must **not** contain the database that
  > needs to be transported.<br/>
  > Should the target contain the DB already, it **will** need to be dropped beforehand.

- The transported DB (but not _other_ DBs on the same source instance) to:

  - Be put in **Read Only** mode.
  - Have all installed extensions **removed**.

To avoid locking the operator's machine for the time needed by the transport, it is suggested the use of an EC2 instance
in the middle to operate on both DBs.

> Try and keep the DBs identifiers under 22 characters.<br/>
> PostgreSQL will try and truncate the identifier after 63 characters, and AWS will add something like
> `.{{12-char-id}}.{{region}}.rds.amazonaws.com` to it.

</details>
<details>
  <summary>Procedure</summary>

1. Enable the required configuration parameters and `pg_transport` extension on the source and target RDS instances.<br/>
   Create a new RDS Parameter Group or modify the existing one used by the source.

   Required parameters:

   - `shared_preload_libraries` **must** include `pg_transport`.
   - `pg_transport.num_workers` **must** be tuned.<br/>
     Its value determines the number of `transport.send_file` workers that will be created in the source. Defaults to 3.
   - `max_worker_processes` **must** be at least (3 * `pg_transport.num_workers`) + 9.<br/>
     Required on the destination to handle various background worker processes involved in the transport.
   - `pg_transport.work_mem` _can_ be tuned.<br/>
     Specifies the maximum memory to allocate to each worker. Defaults to 131072 (128 MB) or 262144 (256 MB) depending
     on the PostgreSQL version.
   - `pg_transport.timing` _can_ be set to `1`.<br/>
     Specifies whether to report timing information during the transport. Defaults to 1 (true), meaning that timing
     information is reported.

1. Reboot the instances equipped with the Parameter Group to apply changes.
1. Create a new _target_ instance with the required allocated storage.
1. Make sure the middleman can connect to both DBs.
1. Make sure the _target_ DB instance can connect to the _source_.
1. Prepare **both** source and target DBs:

   1. Connect to the DB:

      ```sh
      psql -h 'source-instance.5f7mp3pt3n6e.eu-west-1.rds.amazonaws.com' -p '5432' -U 'admin' --password
      psql -h 'target-instance.5f7mp3pt3n6e.eu-west-1.rds.amazonaws.com' -p '5432' -U 'admin' --password 'postgres'
      ```

   1. **Remove** all extensions but `pg_transport` from the public schema of the DB instance.<br/>
      Only the `pg_transport` extension is allowed during the actual transport operation.

      ```sql
      SELECT "extname" FROM "pg_extension";
      DROP EXTENSION "plpgsql", "postgis", "…" CASCADE;
      ```

   1. Install the `pg_transport` extension if missing:

      ```sql
      CREATE EXTENSION "pg_transport";
      ```

1. \[optional] Test the transport by running the `transport.import_from_server` function on the **target** DB instance:

   ```sql
   -- Keep arguments in *single* quotes here
   SELECT transport.import_from_server(
     'source-instance.5f7mp3pt3n6e.eu-west-1.rds.amazonaws.com', 5432,
     'admin', 'source-user-password', 'mySourceDb',
     'target-user-password',
     true
   );
   ```

1. Run the transport by running the `transport.import_from_server` function on the **target** DB instance:

   ```sql
   SELECT transport.import_from_server( …, …, …, …, …, …, false);
   ```

1. Validate the data in the target.
1. Add all the needed roles and permissions to the target.
1. Restore uninstalled extensions in the public schema of **both** DB instances.<br/>
   `pg_transport` _can_ be uninstalled.
1. Revert the value of the max_worker_processes parameter.

</details>
<br/>

If the target DB instance has automatic backups enabled, a backup is automatically taken after transport completes.<br/>
Point-in-time restores will be available for times after the backup finishes.

Should the transport fail, the `pg_transport` extension will attempt to undo all changes to the source **and** target DB
instances. This includes removing the destination's partially transported database.<br/>
Depending on the type of failure, the source database might continue to reject write-enabled queries. Should this
happen, allow write-enabled queries manually:

```sql
ALTER DATABASE db-name SET default_transaction_read_only = false;
```

## Troubleshooting

### ERROR: extension must be loaded via shared_preload_libraries

Refer [How can I resolve the "ERROR: <module/extension> must be loaded via shared_preload_libraries" error?]

## Further readings

- [Working with DB instance read replicas]
- [Working with parameter groups]
- [How can I resolve the "ERROR: <module/extension> must be loaded via shared_preload_libraries" error?]

### Sources

- [Pricing and data retention for Performance Insights]
- [Introduction to backups]
- [Restoring from a DB snapshot]
- [AWS KMS key management]
- [Amazon RDS DB instance storage]
- [How can I decrease the total provisioned storage size of my Amazon RDS DB instance?]
- [What is AWS Database Migration Service?]
- [Migrating databases to their Amazon RDS equivalents with AWS DMS]
- [Transporting PostgreSQL databases between DB instances]
- [Migrating databases using RDS PostgreSQL Transportable Databases]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[s3]: s3.md

<!-- Files -->
<!-- Upstream -->
[amazon rds db instance storage]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Storage.html
[aws kms key management]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.Encryption.Keys.html
[how can i decrease the total provisioned storage size of my amazon rds db instance?]: https://repost.aws/knowledge-center/rds-db-storage-size
[how can i resolve the "error: <module/extension> must be loaded via shared_preload_libraries" error?]: https://repost.aws/knowledge-center/rds-postgresql-resolve-preload-error
[introduction to backups]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithAutomatedBackups.html
[migrating databases to their amazon rds equivalents with aws dms]: https://docs.aws.amazon.com/dms/latest/userguide/data-migrations.html
[migrating databases using rds postgresql transportable databases]: https://aws.amazon.com/blogs/database/migrating-databases-using-rds-postgresql-transportable-databases/
[pricing and data retention for performance insights]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.Overview.cost.html
[restoring from a db snapshot]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_RestoreFromSnapshot.html
[transport postgresql databases between two amazon rds db instances using pg_transport]: https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/transport-postgresql-databases-between-two-amazon-rds-db-instances-using-pg_transport.html
[transporting postgresql databases between db instances]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/PostgreSQL.TransportableDB.html
[what is aws database migration service?]: https://docs.aws.amazon.com/dms/latest/userguide/Welcome.html
[working with db instance read replicas]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html
[working with parameter groups]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html

<!-- Others -->
