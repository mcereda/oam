# Amazon OpenSearch Service

Amazon offering for managed OpenSearch clusters.

1. [Storage](#storage)
   1. [UltraWarm storage](#ultrawarm-storage)
   1. [Cold storage](#cold-storage)
1. [Operations](#operations)
   1. [Migrate indexes to UltraWarm storage](#migrate-indexes-to-ultrawarm-storage)
   1. [Return warm indexes to hot storage](#return-warm-indexes-to-hot-storage)
   1. [Migrate indexes to Cold storage](#migrate-indexes-to-cold-storage)
1. [Best practices](#best-practices)
   1. [Dedicated master nodes](#dedicated-master-nodes)
1. [Cost-saving measures](#cost-saving-measures)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Storage

_Standard_ data nodes use _hot_ storage in the form of instance stores or EBS volumes attached to each node.<br/>
Hot storage provides the fastest possible performance for indexing and searching new data.

_UltraWarm_ nodes use S3 and caching.<br/>
Useful for indexes that are **not** actively written to, queried less frequently, or don't need the hot storage's
performance.

> Warm indexes are **read-only** unless returned to hot storage.<br/>
> This makes UltraWarm storage best-suited for immutable data such as logs.

Warm indexes behave like any other index.

_Cold_ storage uses s3 too. It is meant for data accessed only occasionally or no longer in active use.<br/>
One **can't** read from nor write to cold indexes. When one needs it, one can selectively attach it to UltraWarm nodes.

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
- There are [limits](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/limits.html#limits-ultrawarm)
  to the amount of storage each instance type can address and the maximum number of warm nodes supported by Domains.
- Amazon recommends a maximum shard size of 50 GiB.
- Upon enablement, UltraWarm might not be available to use for several hours even if the domain state is _Active_.
- Use [Index State Management][index state management in amazon opensearch service] to automate indexes migration to
  UltraWarm after they meet specific conditions.

> Before disabling UltraWarm, one **must** either delete **all** warm indexes or migrate them back to hot storage.<br/>
> After warm storage is empty, wait five minutes before attempting to disable UltraWarm.

### Cold storage

Refer [Cold storage for Amazon OpenSearch Service].

Requirements:

- OpenSearch/ElasticSearch >= v7.9.
- [UltraWarm storage] enabled for the same domain.

## Operations

### Migrate indexes to UltraWarm storage

> Indexes' health **must** be green to perform migrations.

Migrations are executed one index at a time, sequentially.<br/>
There can be up to 200 migrations in the queue.<br/>
Any request that exceeds the limit will be rejected.

> Index migrations to UltraWarm storage require a force merge operation, which purges documents that were marked for
> deletion.<br/>
> By default, UltraWarm merges indexes into one segment. One can set this value up to 1000.

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

### Return warm indexes to hot storage

Migrate them back to hot storage:

```plaintext
POST _ultrawarm/migration/my-index/_hot
```

There can be up to 10 queued migrations from warm to hot storage at a time.<br/>
Migrations requests are processed one at a time in the order they were queued.

Indexes return to hot storage with **one** replica.

### Migrate indexes to Cold storage

As for [UltraWarm storage][migrate indexes to ultrawarm storage], just change the endpoints accordingly:

```plaintext
POST _ultrawarm/migration/my-index/_cold
GET _ultrawarm/migration/my-index/_status
POST _ultrawarm/migration/_cancel/my-index

GET _cold/indices/_search

POST _cold/migration/_warm
GET _cold/migration/my-index/_status
POST _cold/migration/my-index/_cancel
```

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
- Tracking the number of indexes in the cluster.
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

Master nodes size is highly correlated with the data instance size and the number of instances, indexes, and shards they
can manage.

## Cost-saving measures

- Choose appropriate [instance types and sizes][supported instance types in amazon opensearch service].<br/>
  Leverage the ability to select them to tailor the service offering to one's needs.
- Consider using reserved instances for long-term savings.
- Enable index-level compression to save storage space and reduce I/O costs.
- Use Index Lifecycle Management policies to move old data in lower storage tiers.
- Consider using [S3] as data store for infrequently accessed or archived data.
- Consider adjusting the frequency and retention period of snapshots.<br/>
  By default, AWS OpenSearch takes **daily** snapshots and retains them for **14 days**.
- If using `gp2` EBS volumes, move to `gp3`.
- Enable autoscaling (serverless only).
- Optimize indexes' sharding and replication.
- Optimize queries.
- Optimize data ingestion.
- Optimize indexes' mapping and settings.
- Optimize the JVM heap size.
- Summarize and compress historical data using Rollups.
- Check out caches.
- Reduce the number of requests using throttling and rate limiting.
- Move to single-AZ deployments.
- Leverage Spot Instances for data ingestion and processing.
- Compress source data before sending it to OpenSearch to reduce the storage footprint and data transfer costs.
- Share a single OpenSearch cluster with multiple accounts to reduce the overall number of instances and resources.

## Further readings

- [OpenSearch]
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

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[migrate indexes to ultrawarm storage]: #migrate-indexes-to-ultrawarm-storage
[ultrawarm storage]: #ultrawarm-storage

<!-- Knowledge base -->
[dedicated master nodes]: #dedicated-master-nodes
[opensearch]: ../../opensearch.md
[s3]: s3.md

<!-- Files -->
<!-- Upstream -->
[best practices for configuring your amazon opensearch service domain]: https://aws.amazon.com/blogs/big-data/best-practices-for-configuring-your-amazon-opensearch-service-domain/
[cold storage for amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/cold-storage.html
[dedicated master nodes in amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/managedomains-dedicatedmasternodes.html
[how do i reduce the cost of using opensearch service domains?]: https://repost.aws/knowledge-center/opensearch-domain-pricing
[index state management in amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ism.html
[lower your amazon opensearch service storage cost with gp3 amazon ebs volumes]: https://aws.amazon.com/blogs/big-data/lower-your-amazon-opensearch-service-storage-cost-with-gp3-amazon-ebs-volumes/
[operational best practices for amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/bp.html
[supported instance types in amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/supported-instance-types.html
[ultrawarm storage for amazon opensearch service]: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ultrawarm.html

<!-- Others -->
[cost-saving strategies for aws opensearch(finops): optimize performance without breaking the bank]: https://ramchandra-vadranam.medium.com/cost-saving-strategies-for-aws-opensearch-finops-optimize-performance-without-breaking-the-bank-f87f0bb2ce37
[opensearch cost optimization: 12 expert tips]: https://opster.com/guides/opensearch/opensearch-capacity-planning/how-to-reduce-opensearch-costs/
[reducing amazon opensearch service costs: our journey to over 60% savings]: https://medium.com/kreuzwerker-gmbh/how-we-accelerate-financial-and-operational-efficiency-with-amazon-opensearch-6b86b41d50a0
[right-size amazon opensearch instances to cut costs by 50% or more]: https://cloudfix.com/blog/right-size-amazon-opensearch-instances-cut-costs/
