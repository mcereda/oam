# Title

Search and analytics suite forked from ElasticSearch by Amazon.<br/>
Makes it easy to ingest, search, visualize, and analyze data.

Use cases: application search, log analytics, data observability, data ingestion, others.

1. [Concepts](#concepts)
   1. [Update lifecycle](#update-lifecycle)
   1. [Translog](#translog)
   1. [Refresh operations](#refresh-operations)
   1. [Flush operations](#flush-operations)
   1. [Merge operations](#merge-operations)
   1. [Node types](#node-types)
   1. [Indexes](#indexes)
1. [Requirements](#requirements)
1. [Quickstart](#quickstart)
1. [Tuning](#tuning)
1. [The split brain problem](#the-split-brain-problem)
1. [APIs](#apis)
1. [Hot-warm architecture](#hot-warm-architecture)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Concepts

_Documents_ are the unit storing information.<br/>
Information is text or structured data.<br/>
Documents are stored in the JSON format and returned when related information is searched for.

_Indexes_ are collections of documents.<br/>
Its contents are queried when information is searched for.

OpenSearch is designed to be a distributed search engine running on one or more _nodes_.<br/>
Nodes are servers that store data and process search requests.

_Clusters_ are collections of nodes allowing for different responsibilities to be taken on by different node types.<br/>
In each cluster a _cluster manager node_ is **elected**. It orchestrates cluster-level operations such as creating an
index.

Nodes in clusters communicate with each other: if a request is routed to a node, it sends requests to other nodes,
gathers their responses, and returns the final response.

Indexes are split into _shards_, each of them storing a subset of all documents in an index.<br/>
Shards are evenly distributed across nodes in a cluster.<br/>
Each shard is effectively a full [Lucene] index. Since each instance of Lucene is a running process consuming CPU and
memory, having more shards is not necessarily better.

Shards may be either _primary_ (original) _replicas_ (copy).<br/>
By default, one replica shard is created for each primary shard.

OpenSearch distributes replica shards to different nodes than their corresponding primary shards so that replica shards
act as backups in the event of node failures.<br/>
Replicas also improve the speed at which the cluster processes search requests, encouraging the use of more than one
replica per index for each search-heavy workload.

Indexes uses a data structure called an _inverted index_. It maps words to the documents in which they occur.<br/>
When searching, OpenSearch matches the words in the query to the words in the documents. Each document is assigned a
_relevance_ score saying how well the document matched the query.

Individual words in a search query are called _search terms_, and each is scored according to the following rules:

- Search terms that occur more frequently in a document will tend to be scored higher.<br/>
  This is the _term frequency_ component of the score.
- Search terms that occur in more documents will tend to be scored lower.<br/>
  This is the _inverse document frequency_ component of the score.
- Matches on longer documents should tend to be scored lower than matches on shorter documents.<br/>
  This corresponds to the _length normalization_ component of the score.

OpenSearch uses the [Okapi BM25] ranking algorithm to calculate document relevance scores and then returns the results
sorted by relevance.

### Update lifecycle

Update operations consist of the following steps:

1. An update is received by a primary shard.
1. The update is written to the shard's transaction log [translog].
1. The [translog] is flushed to disk and followed by an `fsync` **before** the update is acknowledged to guarantee
   durability.
1. The update is passed to the [Lucene] index writer, which adds it to an in-memory buffer.
1. On a refresh operation, the Lucene index writer flushes the in-memory buffers to disk.<br/>
   Each buffer becomes a new Lucene segment.
1. A new index reader is opened over the resulting segment files.<br/>
   The updates are now visible for search.
1. On a flush operation, the shard `fsync`s the Lucene segments.<br/>
   Because the segment files are a durable representation of the updates, the translog is no longer needed to provide
   durability. The updates can be purged from the translog.

### Translog

Transition log making updates durable.

Indexing or bulk calls respond when the documents have been written to the translog and the translog is flushed to disk.<br/>
Updates will **not** be visible to search requests until after a [refresh operation][refresh operations].

### Refresh operations

Performed periodically to write the documents from the in-memory [Lucene] index to files.<br/>
These files are not guaranteed to be durable, because an `fsync` is **not** performed at this point.

A refresh makes documents available for search.

### Flush operations

Persist the files to disk using `fsync`, ensuring durability.<br/>
Flushing ensures that the data stored only in the translog is recorded in the [Lucene] index.

Flushes are performed as needed to ensure that the translog does not grow too large.

### Merge operations

Shards are [Lucene] indexes, which consist of segments (or segment files).<br/>
Segments store the indexed data and are **immutable**.

Smaller segments are merged into larger ones periodically to reduce the overall number of segments on each shard, free
up disk space, and improve search performance.

Eventually, segments reach a maximum size and are no longer merged into larger segments.<br/>
Merge policies specify the maximum size and how often merges are performed.

### Node types

| Node type                | Description                                                                                                                                                                                                                                                                                               | Best practices for production                                                                                                                                                                                                  |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Cluster manager          | Manages the overall operation of a cluster and keeps track of the cluster state.<br/>This includes creating and deleting indexes, keeping track of the nodes that join and leave the cluster, checking the health of each node in the cluster (by running ping requests), and allocating shards to nodes. | Three dedicated cluster manager nodes in three different availability zones ensures the cluster never loses quorum.<br/>Two nodes will be idle for most of the time, except when one node goes down or needs some maintenance. |
| Cluster manager eligible | Elects one node among them as the cluster manager node through a voting process.                                                                                                                                                                                                                          | Make sure to have dedicated cluster manager nodes by marking all other node types as not cluster manager eligible.                                                                                                             |
| Data                     | Stores and searches data.<br/>Performs all data-related operations (indexing, searching, aggregating) on local shards.<br/>These are the worker nodes and need more disk space than any other node type.                                                                                                  | Keep them balanced between zones.<br/>Storage and RAM-heavy nodes are recommended.                                                                                                                                             |
| Ingest                   | Pre-processes data before storing it in the cluster.<br/>Runs an ingest pipeline that transforms data before adding it to an index.                                                                                                                                                                       | Use dedicated ingest nodes if you plan to ingest a lot of data and run complex ingest pipelines.<br/>Optionally offload your indexing from the data nodes so that they are used exclusively for searching and aggregating.     |
| Coordinating             | Delegates client requests to the shards on the data nodes, collects and aggregates the results into one final result, and sends this result back to the client.                                                                                                                                           | Prevent bottlenecks for search-heavy workloads using a couple of dedicated coordinating-only nodes.<br/>Use CPUs with as many cores as you can.                                                                                |
| Dynamic                  | Delegates specific nodes for custom work (e.g.: machine learning tasks), preventing the consumption of resources from data nodes and therefore not affecting functionality.                                                                                                                               |                                                                                                                                                                                                                                |
| Search                   | Provides access to searchable snapshots.<br/>Incorporates techniques like frequently caching used segments and removing the least used data segments in order to access the searchable snapshot index (stored in a remote long-term storage source, for example, Amazon S3 or Google Cloud Storage).      | Use nodes with more compute (CPU and memory) than storage capacity (hard disk).                                                                                                                                                |

Each node is a cluster-manager-eligible, data, ingest, **and** coordinating node by default.<br/>
Number of nodes, assigning node types, and choosing the hardware for each node type should depend on one's own use case.
One should take into account factors like the amount of time to hold on to data, the average size of documents, typical
workload (indexing, searches, aggregations), expected price-performance ratio, risk tolerance, and so on.

After assessing all requirements, it is suggested to use benchmark testing tools like OpenSearch Benchmark.<br/>
Provision a small sample cluster and run tests with varying workloads and configurations. Compare and analyze the system
and query metrics for these tests improve upon the architecture.

### Indexes

Data is indexed using the REST API.

There are two indexing APIs: the index API and the `_bulk` API.<br/>
The Index API adds documents individually as they arrive, so it is intended for situations in which new data arrives
incrementally (i.e., customer orders from a small business).<br/>
The `_bulk` API takes in one file lumping requests together, offering superior performance for situations in which the
flow of data is less frequent and can be aggregated in a generated file.<br/>
Enormous documents should still be indexed individually.

When indexing documents, the document's `_id` must be 512 bytes or less in size.

_Static_ index settings can only be updated on **closed** indexes.<br/>
_Dynamic_ index settings can be updated at any time through the [APIs].

## Requirements

| Port number | Component                                                                        |
| ----------- | -------------------------------------------------------------------------------- |
| 443         | OpenSearch Dashboards in AWS OpenSearch Service with encryption in transit (TLS) |
| 5601        | OpenSearch Dashboards                                                            |
| 9200        | OpenSearch REST API                                                              |
| 9300        | Node communication and transport (internal), cross cluster search                |
| 9600        | Performance Analyzer                                                             |

For Linux hosts:

- `vm.max_map_count` must be set to at least 262144.

## Quickstart

Use docker compose.

1. Disable memory paging and swapping **on Linux hosts** to improve performance and increase the number of maps
   available to the service:

   ```sh
   sudo swapoff -a
   sudo echo '262144' > '/proc/sys/vm/max_map_count'
   ```

1. Get the sample compose file:

   ```sh
   curl -O 'https://raw.githubusercontent.com/opensearch-project/documentation-website/2.14/assets/examples/docker-compose.yml'
   ```

1. Adjust the compose file and run it:

   ```sh
   docker compose up -d
   ```

## Tuning

- Disable swapping.<br/>
  If kept enabled, it can dramatically **decrease** performance and stability.
- Avoid using network file systems for node storage in a production workflow.<br/>
  Using those can cause performance issues due to network conditions (i.e.: latency, limited throughput) or read/write
  speeds.
- Use solid-state drives (SSDs) on the hosts for node storage where possible.
- Set the size of the Java heap.<br/>
  Recommended to use **half** of the system's RAM.
- Set up a [hot-warm architecture].

## The split brain problem

TODO

## APIs

FIXME: expand

- Close indexes.<br/>
  Disables read and write operations.

  ```plaintext
  POST /prometheus-logs-20231205/_close
  ```

- (Re)Open closed indexes.<br/>
  Enables read and write operations.

  ```plaintext
  POST /prometheus-logs-20231205/_open
  ```

- Update indexes' settings.<br/>
  _Static_ settings can only be updated on **closed** indexes.

  ```plaintext
  PUT /prometheus-logs-20231205/_settings
  {
    "index": {
      "codec": "zstd_no_dict",
      "codec.compression_level": 3,
      "refresh_interval": "2s"
    }
  }
  ```

## Hot-warm architecture

Refer
[Set up a hot-warm architecture](https://opensearch.org/docs/latest/tuning-your-cluster/#advanced-step-7-set-up-a-hot-warm-architecture).

## Further readings

- [Website]
- [Github]
- [Documentation]
- [Lucene]
- [Okapi BM25]
- [`fsync`][fsync]
- [AWS' managed OpenSearch] offering
- [Setting up Hot-Warm architecture for ISM in OpenSearch]

### Sources

- [What is OpenSearch?]
- [Creating a cluster]
- [Elasticsearch split brain]
- [Avoiding the Elasticsearch split brain problem, and how to recover]
- [Index templates in OpenSearch - how to use composable templates]
- [Index management]
- [Index settings]
- [Elasticsearch Index Lifecycle Management & Policy]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[apis]: #apis
[hot-warm architecture]: #hot-warm-architecture
[refresh operations]: #refresh-operations
[translog]: #translog

<!-- Knowledge base -->
[AWS' managed OpenSearch]: cloud%20computing/aws/opensearch.md

<!-- Files -->
<!-- Upstream -->
[creating a cluster]: https://opensearch.org/docs/latest/tuning-your-cluster/
[documentation]: https://opensearch.org/docs/latest/
[github]: https://github.com/opensearch-project
[index management]: https://opensearch.org/docs/latest/dashboards/im-dashboards/index-management/
[index settings]: https://opensearch.org/docs/latest/install-and-configure/configuring-opensearch/index-settings/
[website]: https://opensearch.org/
[what is opensearch?]: https://aws.amazon.com/what-is/opensearch/

<!-- Others -->
[avoiding the elasticsearch split brain problem, and how to recover]: https://bigdataboutique.com/blog/avoiding-the-elasticsearch-split-brain-problem-and-how-to-recover-f6451c
[elasticsearch index lifecycle management & policy]: https://opster.com/guides/elasticsearch/data-architecture/index-lifecycle-policy-management/
[elasticsearch split brain]: https://opster.com/guides/elasticsearch/best-practices/elasticsearch-split-brain/
[fsync]: https://man7.org/linux/man-pages/man2/fsync.2.html
[index templates in opensearch - how to use composable templates]: https://opster.com/guides/opensearch/opensearch-data-architecture/index-templating-in-opensearch-how-to-use-composable-templates/
[lucene]: https://lucene.apache.org/
[okapi bm25]: https://en.wikipedia.org/wiki/Okapi_BM25
[setting up hot-warm architecture for ism in opensearch]: https://opster.com/guides/opensearch/opensearch-data-architecture/setting-up-hot-warm-architecture-for-ism/
