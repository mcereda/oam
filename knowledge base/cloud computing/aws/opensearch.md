# Amazon OpenSearch Service

Amazon offering for managed OpenSearch clusters.

1. [Storage](#storage)
   1. [UltraWarm storage](#ultrawarm-storage)
   1. [Cold storage](#cold-storage)
1. [Operations](#operations)
   1. [Migrate indices to UltraWarm storage](#migrate-indices-to-ultrawarm-storage)
   1. [Return warm indices to hot storage](#return-warm-indices-to-hot-storage)
   1. [Migrate indices to Cold storage](#migrate-indices-to-cold-storage)
1. [Index state management plugin](#index-state-management-plugin)
1. [Snapshots](#snapshots)
1. [Best practices](#best-practices)
   1. [Dedicated master nodes](#dedicated-master-nodes)
1. [Cost-saving measures](#cost-saving-measures)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Storage

Clusters can be set up to use the [hot-warm architecture].<br/>
Compared to the plain OpenSearch product, AWS' managed OpenSearch service offers the two extra `UltraWarm` and `Cold`
storage options.

_Hot_ storage provides the fastest possible performance for indexing and searching **new** data.<br/>
_Data_ nodes use **hot** storage in the form of instance stores or EBS volumes attached to each node.

Indices that are **not** actively written to (e.g., immutable data like logs), that are queried less frequently, or that
don't need the hot storage's performance can be moved to _warm_ storage.

Warm indices are **read-only** unless returned to hot storage.<br/>
Aside that, they behave like any other hot index.

[_UltraWarm_][ultrawarm storage for amazon opensearch service] nodes use **warm** storage in the form of S3 and caching.

_Cold_ storage is meant for data accessed only occasionally or no longer in active use.<br/>
Cold indices are normally detached from nodes and stored in S3, meaning one **can't** read from nor write to cold
indices by default. Should one need to query them, one needs to selectively attach them to UltraWarm nodes.

If using the [hot-warm architecture], leverage the [Index State Management plugin] to automate indices migration to
lower storage states after they meet specific conditions.

### UltraWarm storage

Refer [UltraWarm storage for Amazon OpenSearch Service].

Requirements:

- OpenSearch/ElasticSearch >= v6.8.
- Dedicated master nodes.
- No `t2` nor `t3` instances types as data nodes.
- When using a Multi-AZ architecture with _Standby_ domain, the number of warm nodes **must** be a multiple of the
  number of Availability Zones being used.
- Others.

Considerations:

- When calculating UltraWarm storage requirements, consider only the size of the primary shards.<br/>
  S3 removes the need for replicas and abstracts away any operating system or service considerations.
- Dashboards and `_cat/indices` will still report UltraWarm index size as the _total_ of all primary and replica shards.
- There are [limits][ultrawarm storage quotas] to the amount of storage each instance type can address and the maximum
  number of warm nodes supported by Domains.
- Amazon recommends a maximum shard size of 50 GiB.
- Upon enablement, UltraWarm might not be available to use for several hours even if the domain state is _Active_.
- The minimum amount of UltraWarm instances allowed by AWS is 2.

> Before disabling UltraWarm, one **must** either delete **all** warm indices or migrate them back to hot storage.<br/>
> After warm storage is empty, wait five minutes before attempting to disable UltraWarm.

### Cold storage

Refer [Cold storage for Amazon OpenSearch Service].

Requirements:

- OpenSearch/ElasticSearch >= v7.9.
- [UltraWarm storage] enabled for the same domain.

Considerations:

- One **can't** read from, nor write to, cold indices.

## Operations

### Migrate indices to UltraWarm storage

> Indices' health **must** be green to perform migrations.

Migrations are executed one index at a time, sequentially.<br/>
There can be up to 200 migrations in the queue.<br/>
Any request that exceeds the limit will be rejected.

> Index migrations to UltraWarm storage require a force merge operation, which purges documents that were marked for
> deletion.<br/>
> By default, UltraWarm merges indices into one segment. One can set this value up to 1000.

Migrations might fail during snapshots, shard relocations, or force merges.<br/>
Failures during snapshots or shard relocation are typically due to node failures or S3 connectivity issues.<br/>
Lack of disk space is usually the underlying cause of force merge failures.

Start migration:

```plaintext
POST _ultrawarm/migration/my-index/_warm
```

Check the migration's status:

```plaintext
GET _ultrawarm/migration/my-index/_status
```

```json
{
  "migration_status": {
    "index": "my-index",
    "state": "RUNNING_SHARD_RELOCATION",
    "migration_type": "HOT_TO_WARM",
    "shard_level_status": {
      "running": 0,
      "total": 5,
      "pending": 3,
      "failed": 0,
      "succeeded": 2
    }
  }
}
```

If a migration is in the queue but has not yet started, it can be removed from the queue:

```plaintext
POST _ultrawarm/migration/_cancel/my-index
```

### Return warm indices to hot storage

Migrate them back to hot storage:

```plaintext
POST _ultrawarm/migration/my-index/_hot
```

There can be up to 10 queued migrations from warm to hot storage at a time.<br/>
Migrations requests are processed one at a time in the order they were queued.

Indices return to hot storage with **one** replica.

### Migrate indices to Cold storage

As for [UltraWarm storage][migrate indices to ultrawarm storage], just change the endpoints accordingly:

```plaintext
POST _ultrawarm/migration/my-index/_cold
GET _ultrawarm/migration/my-index/_status
POST _ultrawarm/migration/_cancel/my-index

GET _cold/indices/_search

POST _cold/migration/_warm
GET _cold/migration/my-index/_status
POST _cold/migration/my-index/_cancel
```

## Index state management plugin

Refer [OpenSearch's Index State Management plugin][opensearch  index state management] and
[Index State Management in Amazon OpenSearch Service].

Compared to [OpenSearch] and [ElasticSearch], ISM for Amazon's managed OpenSearch service has several differences:

- The managed OpenSearch service supports the three unique ISM operations `warm_migration`, `cold_migration`, and
  `cold_delete`.

  If one's domain has [UltraWarm storage] enabled, the `warm_migration` action transitions indices to warm storage.<br/>
  If one's domain has [cold storage] enabled, the `cold_migration` action transitions indices to cold storage, and the
  `cold_delete` action deletes them from cold storage.

  Should one of these actions not complete within the set timeout period, the migration or deletion of the affected
  indices will continue.<br/>
  Setting an `error_notification` for one of the above actions will send a notification about the action failing,
  should it not complete within the timeout period, but the notification is only for one's own reference. The actual
  operation has no inherent timeout, and will continue to run until it eventually succeeds or fails.

- \[should the domain run OpenSearch or Elasticsearch 7.4 or later] The managed OpenSearch service supports the ISM
  `open` and `close` operations.
- \[should the domain run OpenSearch or Elasticsearch 7.7 or later] The managed OpenSearch service supports the ISM
  `snapshot` operation.

- Cold indices API:
  - Require specifying the `?type=_cold` parameter when you use the following ISM APIs:
    - Add policy
    - Remove policy
    - Update policy
    - Retry failed index
    - Explain index
  - Do **not** support wildcard operators, except when used at the end of the path.<br/>
    I.E., `_plugins/_ism/add/logstash-*` is supported, but `_plugins/_ism/add/iad-*-prod` is not.
  - Do **not** support multiple index names and patterns.<br/>
    I.E., `_plugins/_ism/remove/app-logs` is supported, but `_plugins/_ism/remove/app-logs,sample-data` is not.

- The managed OpenSearch service allows to change only the following ISM settings:
  - `plugins.index_state_management.enabled` and `plugins.index_state_management.history.enabled` at cluster level.
  - `plugins.index_state_management.rollover_alias` at index level.

## Snapshots

Refer [Snapshots][opensearch  snapshots] and [Creating index snapshots in Amazon OpenSearch Service].

AWS-managed OpenSearch Service snapshots come in the following forms:

- _Automated_ snapshots: only for cluster recovery, stored in a **preconfigured** S3 bucket at **no** additional
  cost.<br/>
  One can use them to restore the domain in the event of red cluster status or data loss.
- _Manual_ snapshots: for cluster recovery or moving data from one cluster to another.<br/>
  Users must be those initiating manual snapshots.<br/>
  These snapshots are stored in one's own S3 bucket. Standard S3 charges apply.

All AWS-managed OpenSearch Service domains take automated snapshots, but with a frequency difference:

- Domains running OpenSearch or Elasticsearch 5.3 and later take **hourly** automated snapshots and retain up to 336 of
  them for 14 days.
- Domains running Elasticsearch 5.1 and earlier take **daily** automated snapshots during off-peak hours and retain up
  to 14 of them. No snapshot data is retained for more than 30 days.

> [!IMPORTANT]
> Should a cluster enter the red status, all automated snapshots will fail for the time that status persists.

To be able to create snapshots manually:

- An S3 bucket must exist to store snapshots.

  > [!IMPORTANT]
  > Manual snapshots do **not** support the S3 Glacier storage class.<br/>
  > Do **not** apply any S3 Glacier lifecycle rule to this bucket.

- An IAM role that delegates permissions to the OpenSearch Service must be defined.<br/>
  This role must be able to act on the S3 bucket above.

  <details style='padding: 0 0 0 1rem'>
    <summary>Trust relationship (A.K.A. assume role policy)</summary>

  ```json
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {
        "Service": "es.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }]
  }
  ```

  </details>

  <details style='padding: 0 0 1rem 1rem'>
    <summary>Policy</summary>

  ```json
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::{{ bucket name here }}",
        "arn:aws:s3:::{{ bucket name here }}/*"
      ]
    }]
  }
  ```

  </details>

- The IAM user or role whose credentials will be used to sign the requests must have permissions to:

  - Pass the role above to the OpenSearch Service.

    <details style='padding: 0 0 1rem 1rem'>
      <summary>Policy</summary>

    ```json
    {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Action": "iam:PassRole",
        "Resource": "arn:aws:iam::{{ aws account id }}:role/{{ role name }}"
      }]
    }
    ```

    </details>

    Should one use the domain's dashboards' dev tools, and should the domain use Cognito for authentication, those
    permissions need to be added to the IAM role that cognito uses for the user pool.

    Should the user or role making the requests be missing such permissions, they might encounter this error when trying
    to register a repository in the next step:

    > User: arn:aws:iam::123456789012:user/MyUserAccount is not authorized to perform: iam:PassRole on resource:
    > arn:aws:iam::123456789012:role/TheSnapshotRole

  - Use the `es:ESHttpPut` action in the domain.

    <details style='padding: 0 0 1rem 1rem'>
      <summary>Policy</summary>

    ```json
    {
      "Version": "2012-10-17",
      "Statement": [{
        "Effect": "Allow",
        "Action": "es:ESHttpPut",
        "Resource": "arn:aws:es:{{ region}}:{{ aws account id }}:domain/{{ domain name }}/*"
      }]
    }
    ```

    </details>

Snapshots can be taken only from indices in the hot or warm storage tiers.<br/>
Only **one** index from warm storage is allowed at a time, and the request **cannot** contain indices in mixed tiers.

## Best practices

Refer [Operational best practices for Amazon OpenSearch Service] and
[Best practices for configuring your Amazon OpenSearch Service domain].

- Use [dedicated master nodes] in **production** clusters.
- Use Multi-AZ deployments in **production** clusters.

### Dedicated master nodes

Refer [Dedicated master nodes in Amazon OpenSearch Service].

They increase cluster stability by performing cluster management tasks.<br/>
They do **not** hold data nor respond to data upload requests.

Only **one** of the dedicated master nodes is active, while the others wait as backup in case the active dedicated
master node fails.

All data upload requests are served by the data nodes, while all cluster management tasks are offloaded to the active
dedicated master node.
Cluster management tasks are:

- Tracking all nodes in the cluster.
- Maintaining routing information for nodes in the cluster.
- Tracking the number of indices in the cluster.
- Tracking the number of shards belonging to each index.
- Updating the cluster state after state changes.<br/>
  I.e., creating an index and adding or removing nodes in the cluster.
- Replicating changes to the cluster state across all nodes in the cluster.
- Monitoring the health of all cluster nodes by sending heartbeat signals.

Use Multi-AZ with Standby **adds** three dedicated master nodes to each OpenSearch Service domain it is enabled
for.

Even deploying in Single-AZ mode, **three** dedicated master nodes are recommended for stability.<br/>
In any case, **never** choose an even number of dedicated master nodes to avoid _split brain_ problems.

If a cluster has an **even** number of master-eligible nodes, OpenSearch and Elasticsearch versions 7.x and later will
ignore one node so that the voting configuration is always an odd number.<br/>
As such, an even number of dedicated master nodes are essentially equivalent to that number - 1.

> If a cluster doesn't have the necessary quorum to elect a new master node, write and read requests to the cluster will
> both fail.<br/>
> This behavior differs from the OpenSearch default.

Master nodes size is highly correlated with the data instance size and the number of instances, indices, and shards they
can manage.

## Cost-saving measures

- Choose appropriate [instance types and sizes][supported instance types in amazon opensearch service].<br/>
  Leverage the ability to select them to tailor the service offering to one's needs.

  > [OR1 instances][or1 storage for amazon opensearch service] **cannot** (currently?) be selected as master nodes.<br/>
  > They must also be selected **at domain creation**.

- Consider using reserved instances for long-term savings.
- Enable index-level compression to save storage space and reduce I/O costs.
- Use Index Lifecycle Management policies to move old data in lower storage tiers.
- Consider using [S3] as data store for infrequently accessed or archived data.
- Consider adjusting the frequency and retention period of snapshots.<br/>
  By default, AWS OpenSearch takes **daily** snapshots and retains them for **14 days**.
- If using `gp2` EBS volumes, move to `gp3`.
- Enable autoscaling (serverless only).
- Optimize indices' sharding and replication.
- Optimize queries.
- Optimize data ingestion.
- Optimize indices' mapping and settings.
- Optimize the JVM heap size.
- Summarize and compress historical data using [index rollups].
- Check out caches.
- Reduce the number of requests using throttling and rate limiting.
- Move to Single-AZ deployments.
- Filter out and compress source data before sending it to OpenSearch to reduce the storage footprint and data transfer
  costs.
- Share a single OpenSearch cluster with multiple accounts to reduce the overall number of instances and resources.

## Further readings

- [OpenSearch]
- [ElasticSearch]
- [Hot-warm architecture]
- [Supported instance types in Amazon OpenSearch Service]

### Sources

- [Cost-saving strategies for AWS OpenSearch(FinOps): optimize performance without breaking the bank]
- [OpenSearch cost optimization: 12 expert tips]
- [How do I reduce the cost of using OpenSearch Service domains?]
- [Right-size Amazon OpenSearch instances to cut costs by 50% or more]
- [Reducing Amazon OpenSearch service costs: our journey to over 60% savings]
- [UltraWarm storage for Amazon OpenSearch Service]
- [Index State Management in Amazon OpenSearch Service]
- [Cold storage for Amazon OpenSearch Service]
- [Lower your Amazon OpenSearch Service storage cost with gp3 Amazon EBS volumes]
- [Dedicated master nodes in Amazon OpenSearch Service]
- [Best practices for configuring your Amazon OpenSearch Service domain]
- [Operational best practices for Amazon OpenSearch Service]
- [OR1 storage for Amazon OpenSearch Service]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Cold storage]: #cold-storage
[Index State Management plugin]: #index-state-management-plugin
[migrate indices to ultrawarm storage]: #migrate-indices-to-ultrawarm-storage
[ultrawarm storage]: #ultrawarm-storage

<!-- Knowledge base -->
[Dedicated master nodes]: #dedicated-master-nodes
[Hot-warm architecture]: ../../opensearch.md#hot-warm-architecture
[ElasticSearch]: ../../elasticsearch.md
[OpenSearch]: ../../opensearch.md
[OpenSearch  index state management]: ../../opensearch.md#index-state-management-plugin
[OpenSearch  snapshots]: ../../opensearch.md#snapshots
[S3]: s3.md

<!-- Files -->
<!-- Upstream -->
[best practices for configuring your amazon opensearch service domain]: https://aws.amazon.com/blogs/big-data/best-practices-for-configuring-your-amazon-opensearch-service-domain/
[Cold storage for amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/cold-storage.html
[Creating index snapshots in Amazon OpenSearch Service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/managedomains-snapshots.html
[dedicated master nodes in amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/managedomains-dedicatedmasternodes.html
[how do i reduce the cost of using opensearch service domains?]: https://repost.aws/knowledge-center/opensearch-domain-pricing
[index state management in amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ism.html
[lower your amazon opensearch service storage cost with gp3 amazon ebs volumes]: https://aws.amazon.com/blogs/big-data/lower-your-amazon-opensearch-service-storage-cost-with-gp3-amazon-ebs-volumes/
[operational best practices for amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/bp.html
[or1 storage for amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/or1.html
[supported instance types in amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/supported-instance-types.html
[ultrawarm storage for amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ultrawarm.html
[UltraWarm storage quotas]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/limits.html#limits-ultrawarm

<!-- Others -->
[cost-saving strategies for aws opensearch(finops): optimize performance without breaking the bank]: https://ramchandra-vadranam.medium.com/cost-saving-strategies-for-aws-opensearch-finops-optimize-performance-without-breaking-the-bank-f87f0bb2ce37
[index rollups]: https://opensearch.org/docs/latest/im-plugin/index-rollups/index/
[opensearch cost optimization: 12 expert tips]: https://opster.com/guides/opensearch/opensearch-capacity-planning/how-to-reduce-opensearch-costs/
[reducing amazon opensearch service costs: our journey to over 60% savings]: https://medium.com/kreuzwerker-gmbh/how-we-accelerate-financial-and-operational-efficiency-with-amazon-opensearch-6b86b41d50a0
[right-size amazon opensearch instances to cut costs by 50% or more]: https://cloudfix.com/blog/right-size-amazon-opensearch-instances-cut-costs/
