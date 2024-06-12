# Amazon OpenSearch Service

Amazon offering for managed OpenSearch clusters.

1. [Cost-saving measures](#cost-saving-measures)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Cost-saving measures

- Choose good instance types and sizes.<br/>
  Leverage the ability to select them to tailor the service offering to one's needs.
- Consider using reserved instances for long-term savings.
- Enable index-level compression to save storage space and reduce I/O costs.
- Use Index Lifecycle Management policies to move old data in lower storage tiers.
- Consider using [S3] as data store for infrequently accessed or archived data.
- Consider adjusting the frequency and retention period of snapshots.<br/>
  By default, AWS OpenSearch takes **daily** snapshots and retains them for **14 days**.
- Enable autoscaling.
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

### Sources

- [Cost-saving strategies for AWS OpenSearch(FinOps): optimize performance without breaking the bank]
- [OpenSearch cost optimization: 12 expert tips]
- [How do I reduce the cost of using OpenSearch Service domains?]
- [Right-size Amazon OpenSearch instances to cut costs by 50% or more]
- [Reducing Amazon OpenSearch service costs: our journey to over 60% savings]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[opensearch]: ../../opensearch.md
[s3]: s3.md

<!-- Files -->
<!-- Upstream -->
[how do i reduce the cost of using opensearch service domains?]: https://repost.aws/knowledge-center/opensearch-domain-pricing

<!-- Others -->
[cost-saving strategies for aws opensearch(finops): optimize performance without breaking the bank]: https://ramchandra-vadranam.medium.com/cost-saving-strategies-for-aws-opensearch-finops-optimize-performance-without-breaking-the-bank-f87f0bb2ce37
[opensearch cost optimization: 12 expert tips]: https://opster.com/guides/opensearch/opensearch-capacity-planning/how-to-reduce-opensearch-costs/
[right-size amazon opensearch instances to cut costs by 50% or more]: https://cloudfix.com/blog/right-size-amazon-opensearch-instances-cut-costs/
[reducing amazon opensearch service costs: our journey to over 60% savings]: https://medium.com/kreuzwerker-gmbh/how-we-accelerate-financial-and-operational-efficiency-with-amazon-opensearch-6b86b41d50a0
