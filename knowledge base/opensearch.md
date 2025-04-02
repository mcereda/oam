# OpenSearch

Search and analytics suite
[forked from ElasticSearch by Amazon][stepping up for a truly open source elasticsearch].<br/>
Makes it easy to ingest, search, visualize, and analyze data.

Use cases: application search, log analytics, data observability, data ingestion, others.

1. [TL;DR](#tldr)
1. [Node types](#node-types)
1. [Indexes](#indexes)
1. [Setup](#setup)
   1. [The split brain problem](#the-split-brain-problem)
   1. [Tuning](#tuning)
   1. [Hot-warm architecture](#hot-warm-architecture)
1. [Index templates](#index-templates)
   1. [Composable index templates](#composable-index-templates)
1. [Ingest data](#ingest-data)
   1. [Bulk indexing](#bulk-indexing)
1. [Re-index data](#re-index-data)
1. [Data streams](#data-streams)
1. [Index patterns](#index-patterns)
1. [APIs](#apis)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

_Documents_ are the unit storing information, consisting of text or structured data.<br/>
Documents are stored in the JSON format, and returned when related information is searched for.<br/>
Documents are immutable. However, they can be updated by retrieving them, updating the information in them, and
re-indexing them using the same document IDs.

[_Indexes_][indexes] are collections of documents.<br/>
Their contents are queried when information is searched for.

_Nodes_ are servers that store data and process search requests.<br/>
OpenSearch is designed to be running on one or more nodes.

Multiple nodes can be aggregated into _Clusters_.<br/>
Clusters allow nodes to specialize for different responsibilities depending on their types.

Each and every cluster **elects** a _cluster manager node_ is **elected**.<br/>
Manager nodes orchestrate cluster-level operations (e.g., creating indexes).

Nodes in clusters communicate with each other.<br/>
When a request is routed to any node, that node sends requests to the others, gathers their responses, and returns the
final response.

Indexes are split into _shards_, each of them storing a subset of all documents in an index.<br/>
Shards are evenly distributed across nodes in a cluster.<br/>
Each shard is effectively a full [Lucene] index. Since each instance of Lucene is a running process consuming CPU and
memory, having more shards is **not** necessarily better.

Shards may be either _primary_ (the original ones) or _replicas_ (copies of the originals).<br/>
By default, one replica shard is created for each primary shard.

OpenSearch distributes replica shards to **different** nodes than the ones hosting their corresponding primary shards,
so that replica shards would act as backups in the event of node failures.<br/>
Replicas also improve the speed at which the cluster processes search requests, encouraging the use of more than one
replica per index for each search-heavy workload.

Indexes use a data structure called an _inverted index_. It maps words to the documents in which they occur.<br/>
When searching, OpenSearch matches the words in the query to the words in the documents. Each document is assigned a
_relevance score_ indicating how well the document matched the query.

Individual words in a search query are called _search terms_.<br/>
Each term is scored according to the following rules:

- Search terms that occur more frequently in a document will tend to be scored **higher**.<br/>
  This is the _term frequency_ component of the score.
- Search terms that occur in more documents will tend to be scored **lower**.<br/>
  This is the _inverse document frequency_ component of the score.
- Matches on longer documents should tend to be scored **lower** than matches on shorter documents.<br/>
  This corresponds to the _length normalization_ component of the score.

OpenSearch uses the [Okapi BM25] ranking algorithm to calculate document relevance scores, then returns the results
sorted by relevance.

_Update operations_ consist of the following steps:

1. An update is received by a primary shard.
1. The update is written to the shard's transaction log (_translog_).
1. The translog is flushed to disk and followed by an `fsync` **before** the update is acknowledged to guarantee
   durability.
1. The update is passed to the [Lucene] index writer, which adds it to an **in-memory** buffer.
1. On a refresh operation, the Lucene index writer flushes the in-memory buffers to disk.<br/>
   Each buffer becomes a new Lucene segment.
1. A new index reader is opened over the resulting segment files.<br/>
   The updates are now visible for search.
1. On a flush operation, the shard `fsync`s the Lucene segments.<br/>
   Because the segment files are a durable representation of the updates, the translog is no longer needed to provide
   durability. The updates can be purged from the translog.

Transition logs make updates durable.<br/>
_Indexing_ or _bulk_ calls respond once the documents have been written to the translog and the translog is flushed to
disk. Updates will **not** be visible to search requests until after a _refresh operation_ takes place.

Refresh operations are performed periodically to write the documents from the in-memory [Lucene] index to files.<br/>
These files are **not** guaranteed to be durable, because **no** _flush operation_ is **yet** performed at this
point.

A refresh operation makes documents available for search.

Flush operations persist files to disk using `fsync`, ensuring durability.<br/>
Flushing ensures that the data stored only in the translog is recorded in the [Lucene] index.

Flushes are performed as needed to ensure that the translog does not grow too large.

Shards are [Lucene] indexes, which consist of segments (or segment files).<br/>
Segments store the indexed data and are **immutable**.

_Merge operations_ merge smaller segments into larger ones periodically.<br/>
This reduces the overall number of segments on each shard, frees up disk space, and improves search performance.

Eventually, segments reach a maximum allowed size and are no longer merged into larger segments.<br/>
_Merge policies_ specify the segments' maximum size and how often merge operations are performed.

Interaction with the cluster is done via REST [APIs].

If indexes do not already exist, OpenSearch automatically creates them while [ingesting data][ingest data].

<details>
  <summary>Typical setup order of operations</summary>

1. \[optional] Create [index templates].
1. \[optional] Create [data streams].
1. \[optional] Create [indexes].
1. [Ingest data].
1. Create [index patterns] for the search dashboard to use.

</details>

## Node types

| Node type                | Description                                                                                                                                                                                                                                                                                               | Best practices for production                                                                                                                                                                                                  |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Cluster manager          | Manages the overall operation of a cluster and keeps track of the cluster state.<br/>This includes creating and deleting indexes, keeping track of the nodes that join and leave the cluster, checking the health of each node in the cluster (by running ping requests), and allocating shards to nodes. | Three dedicated cluster manager nodes in three different availability zones ensures the cluster never loses quorum.<br/>Two nodes will be idle for most of the time, except when one node goes down or needs some maintenance. |
| Cluster manager eligible | Elects one node among them as the cluster manager node through a voting process.                                                                                                                                                                                                                          | Make sure to have dedicated cluster manager nodes by marking all other node types as not cluster manager eligible.                                                                                                             |
| Data                     | Stores and searches data.<br/>Performs all data-related operations (indexing, searching, aggregating) on local shards.<br/>These are the worker nodes and need more disk space than any other node type.                                                                                                  | Keep them balanced between zones.<br/>Storage and RAM-heavy nodes are recommended.                                                                                                                                             |
| Ingest                   | Pre-processes data before storing it in the cluster.<br/>Runs an ingest pipeline that transforms data before adding it to an index.                                                                                                                                                                       | Use dedicated ingest nodes if you plan to ingest a lot of data and run complex ingest pipelines.<br/>Optionally offload your indexing from the data nodes so that they are used exclusively for searching and aggregating.     |
| Coordinating             | Delegates client requests to the shards on the data nodes, collects and aggregates the results into one final result, and sends this result back to the client.                                                                                                                                           | Prevent bottlenecks for search-heavy workloads using a couple of dedicated coordinating-only nodes.<br/>Use CPUs with as many cores as you can.                                                                                |
| Dynamic                  | Delegates specific nodes for custom work (e.g.: machine learning tasks), preventing the consumption of resources from data nodes and therefore not affecting functionality.                                                                                                                               |                                                                                                                                                                                                                                |
| Search                   | Provides access to searchable snapshots.<br/>Incorporates techniques like frequently caching used segments and removing the least used data segments in order to access the searchable snapshot index (stored in a remote long-term storage source, for example, Amazon S3 or Google Cloud Storage).      | Use nodes with more compute (CPU and memory) than storage capacity (hard disk).                                                                                                                                                |

Each node is by default a cluster-manager-eligible, data, ingest, **and** coordinating node.

Number of nodes, assigning node types, and choosing the hardware for each node type should depend on one's own use
case.<br/>
One should take into account factors like the amount of time to hold on to data, the average size of documents, typical
workload (indexing, searches, aggregations), expected price-performance ratio, risk tolerance, and so on.

After assessing all requirements, it is suggested to use benchmark testing tools like OpenSearch Benchmark.<br/>
Provision a small sample cluster and run tests with varying workloads and configurations. Compare and analyze the system
and query metrics for these tests improve upon the architecture.

## Indexes

Refer [Managing indexes].

Indexes are collections of documents that one wants to make searchable.<br/>
They organize the data for fast retrieval.

To maximise one's ability to search and analyse documents, one can define how documents and their fields are stored and
indexed.

Before one can search through one's data, documents **must** be ingested and indexed.<br/>
Data is ingested and indexed using the [APIs].<br/>
There are two _indexing APIs_:

- The _Index API_, which adds documents individually as they arrive.<br/>
  It is intended for situations in which new data arrives incrementally (i.e., logs, or customer orders from a small
  business).
- The `_bulk` API, which takes in one file lumping requests together.<br/>
  It offers superior performance for situations where the flow of data is _less_ frequent, and/or can be aggregated in a
  generated file.

  Enormous documents are still better indexed **individually**.

Within indexes, OpenSearch identifies each document using a **unique** _document ID_.<br/>
The document's `_id` must be **up to** 512 bytes in size.<br/>
Should one **not** provide an ID for the document during ingestion, OpenSearch generates a document ID itself.

Upon receiving indexing requests, OpenSearch:

1. Creates an index if it does not exist already.
1. Stores the ingested document in that index.

Indexes must follow these naming restrictions:

- All letters must be **lowercase**.
- Index names cannot begin with underscores (`_`) or hyphens (`-`).
- Index names cannot contain spaces, commas, or the following characters: `:`, `"`, `*`, `+`, `/`, `\`, `|`, `?`, `#`,
  `>`, or `<`.

Indexes are configured with _mappings_ and _settings_:

- Mappings are collections of fields and the types of those fields.
- Settings include index data (i.e., the index name, creation date, and number of shards).

One can specify both mappings and settings in a single request.

Unless an index's type mapping is explicitly defined, OpenSearch infers the field types from the JSON types submitted in
the documents for the index (_dynamic mapping_).

Fields mapped to `text` are analyzed (lowercased and split into terms) and can be used for full-text search.<br/>
Fields mapped to `keyword` are used for exact term search.

Numbers are usually dynamically mapped to `long`.<br/>
Should one want to map them to the `date` type instead, one **will** need to delete the index, then recreate it by
explicitly specifying the mappings.

_Static_ index settings can only be updated on **closed** indexes.<br/>
_Dynamic_ index settings can be updated at any time through the [APIs].

## Setup

<details>
  <summary>Requirements</summary>

| Port number | Component                                                                        |
| ----------- | -------------------------------------------------------------------------------- |
| 443         | OpenSearch Dashboards in AWS OpenSearch Service with encryption in transit (TLS) |
| 5601        | OpenSearch Dashboards                                                            |
| 9200        | OpenSearch REST API                                                              |
| 9300        | Node communication and transport (internal), cross cluster search                |
| 9600        | Performance Analyzer                                                             |

For Linux hosts:

- `vm.max_map_count` must be set to 262144 or higher.

</details>

<details>
  <summary>Quickstart</summary>

Just use the Docker composition.

1. Disable memory paging and swapping to improve performance.

   <details style="padding: 0 0 1em 1em">
     <summary>Linux</summary>

   ```sh
   sudo swapoff -a
   ```

   </details>

1. \[on Linux hosts] Increase the number of maps available to the service.

   <details style="padding: 0 0 1em 1em">
     <summary>Linux</summary>

   ```sh
   # temporarily
   sudo echo '262144' > '/proc/sys/vm/max_map_count'

   # permanently
   echo 'vm.max_map_count=262144' | sudo tee -a '/etc/sysctl.conf'
   sudo sysctl -p
   ```

   </details>

1. Get the sample compose file:

   ```sh
   # pick one
   curl -O 'https://raw.githubusercontent.com/opensearch-project/documentation-website/2.19/assets/examples/docker-compose.yml'
   wget 'https://raw.githubusercontent.com/opensearch-project/documentation-website/2.19/assets/examples/docker-compose.yml'
   ```

1. Adjust the compose file as you see fit, then run it.

   The setup requires a **strong** password to be configured, or it will quit midway.<br/>
   At least 8 characters of which 1 uppercase, 1 lowercase, 1 digit and 1 special.

   ```sh
   OPENSEARCH_INITIAL_ADMIN_PASSWORD='someCustomStr0ng!Password' docker compose up -d
   ```

   <details style="padding: 0 0 1em 1em">
     <summary>Confirm that the containers are running</summary>

   ```sh
   $ docker compose ps
   NAME                    COMMAND                  SERVICE                 STATUS    PORTS
   opensearch-dashboards   "./opensearch-dashbo…"   opensearch-dashboards   running   0.0.0.0:5601->5601/tcp
   opensearch-node1        "./opensearch-docker…"   opensearch-node1        running   0.0.0.0:9200->9200/tcp, 9300/tcp, 0.0.0.0:9600->9600/tcp, 9650/tcp
   opensearch-node2        "./opensearch-docker…"   opensearch-node2        running   9200/tcp, 9300/tcp, 9600/tcp, 9650/tcp
   ```

   </details>

1. Query the APIs to verify that the service is running.<br/>
   Disable hostname checking, since the default security configuration uses demo certificates.

   <details style="padding: 0 0 1em 1em">

   ```sh
   curl 'https://localhost:9200' -ku 'admin:someCustomStr0ng!Password'
   ```

   ```json
   {
       "name" : "opensearch-node1",
       "cluster_name" : "opensearch-cluster",
       "cluster_uuid" : "Cp2VzzkjR4eqlzK5H5ERJw",
       "version" : {
           "distribution" : "opensearch",
           "number" : "2.19.1",
           "build_type" : "tar",
           "build_hash" : "2e4741fb45d1b150aaeeadf66d41445b23ff5982",
           "build_date" : "2025-02-27T01:22:24.665339607Z",
           "build_snapshot" : false,
           "lucene_version" : "9.12.1",
           "minimum_wire_compatibility_version" : "7.10.0",
           "minimum_index_compatibility_version" : "7.0.0"
       },
       "tagline" : "The OpenSearch Project: https://opensearch.org/"
   }
   ```

   </details>

1. Explore OpenSearch Dashboards by opening `http://localhost:5601/` in a web browser from the same host that is running
   the OpenSearch cluster.<br/>
   The default username is `admin`, and the password is the one configured in the steps above.

1. Continue interacting with the cluster from the Dashboards, or using the [APIs] or clients.

</details>

<details>
  <summary>Tutorial requests</summary>

```plaintext
PUT /students/_doc/1
{
    "name": "John Doe",
    "gpa": 3.89,
    "grad_year": 2022
}

GET /students/_mapping

GET /students/_search
{
    "query": {
        "match_all": {}
    }
}

PUT /students/_doc/1
{
    "name": "John Doe",
    "gpa": 3.91,
    "grad_year": 2022,
    "address": "123 Main St."
}

POST /students/_update/1/
{
    "doc": {
        "gpa": 3.92,
        "address": "123 Main St."
    }
}

DELETE /students/_doc/1

DELETE /students

PUT /students
{
    "settings": {
        "index.number_of_shards": 1
    },
    "mappings": {
        "properties": {
            "name": {
                "type": "text"
            },
            "grad_year": {
                "type": "date"
            }
        }
    }
}

PUT /students/_doc/1
{
    "name": "John Doe",
    "gpa": 3.89,
    "grad_year": 2022
}

GET /students/_mapping

POST _bulk
{ "create": { "_index": "students", "_id": "2" } }
{ "name": "Jonathan Powers", "gpa": 3.85, "grad_year": 2025 }
{ "create": { "_index": "students", "_id": "3" } }
{ "name": "Jane Doe", "gpa": 3.52, "grad_year": 2024 }
```

</details>

### The split brain problem

TODO

Refer [Elasticsearch Split Brain] and [Avoiding the Elasticsearch split brain problem, and how to recover].

### Tuning

- Disable swapping.<br/>
  If kept enabled, it can **dramatically decrease** performance and stability.
- **Avoid** using network file systems for node storage in a production workflows.<br/>
  Using those can cause performance issues due to network conditions (i.e.: latency, limited throughput) or read/write
  speeds.
- Use solid-state drives (SSDs) on the hosts for node storage where possible.
- Properly set the size of the Java heap.<br/>
  Recommended to use **half** of the host's RAM.
- Set up a [hot-warm architecture].

### Hot-warm architecture

Refer [Set up a hot-warm architecture].

## Index templates

Refer [Index templates][documentation  index templates].

Index templates allow to initialize new indexes with predefined mappings and settings.

### Composable index templates

Composable index templates can be used to overcome challenges from index template management like index template
duplication and changes across all index templates.

Composable index templates abstract common settings, mappings, and aliases into reusable building blocks.<br/>
Those are called _component templates_.

One can combine component templates to compose index templates.

Settings and mappings specified directly in the create index request will override any settings or mappings specified in
an index template and its component templates.

## Ingest data

One can ingest data by:

- Ingesting **individual** documents.
- Indexing **multiple documents in bulk**.
- Using [Data Prepper], a server-side data collector.
- Using other ingestion tools.

### Bulk indexing

Leverage the `_bulk` API endpoint to index documents in bulk.

<details>

```plaintext
POST _bulk
{ "create": { "_index": "students", "_id": "2" } }
{ "name": "Jonathan Powers", "gpa": 3.85, "grad_year": 2025 }
{ "create": { "_index": "students", "_id": "3" } }
{ "name": "Jane Doe", "gpa": 3.52, "grad_year": 2024 }
```

```json
{
    "took": 7,
    "errors": false,
    "items": [
        {
            "create": {
                "_index": "students",
                "_id": "2",
                "_version": 1,
                "result": "created",
                "_shards": {
                    "total": 2,
                    "successful": 2,
                    "failed": 0
                },
                "_seq_no": 1,
                "_primary_term": 1,
                "status": 201
            }
        },
        {
            "create": {
                "_index": "students",
                "_id": "3",
                "_version": 1,
                "result": "created",
                "_shards": {
                    "total": 2,
                    "successful": 2,
                    "failed": 0
                },
                "_seq_no": 2,
                "_primary_term": 1,
                "status": 201
            }
        }
    ]
}
```

If any one of the actions in the `_bulk` API endpoint fail, OpenSearch continues to execute the other actions.

Examine the items array in the response to figure out what went wrong.<br/>
The entries in the items array are in the same order as the actions specified in the request.

</details>

## Re-index data

Refer [Reindex data].

The `_reindex` operation copies documents from an index, that one selects through a query, over to another index.

When needing to make an extensive change (e.g., adding a new field to every document, move documents between indexes, or
combining multiple indexes into a new one), one can use the `_reindex` operation instead of deleting the old indexes,
making the change offline, and then indexing the data again.

Re-indexing can be an expensive operation depending on the size of the source index.<br/>
It is recommended to disable replicas in the destination index by setting its `number_of_replicas` to `0`, and re-enable
them once the re-indexing process is complete.

`_reindex` is a `POST` operation.<br/>
In its most basic form, requires specifying a source index and a destination index.

Should the destination index not exist, `_reindex` creates a new index **with default configurations**.<br/>
If the destination index requires field mappings or custom settings, (re)create the destination index **beforehand**
with the desired ones.

<details>
  <summary>Reindex <b>all</b> documents</summary>

Copy **all** documents from one index to another.

```plaintext
POST _reindex
{
    "source": {
        "index": "sourceIndex"
    },
    "dest": {
        "index": "destinationIndex"
    }
}
```

```json
{
    "took": 1350,
    "timed_out": false,
    "total": 30,
    "updated": 0,
    "created": 30,
    "deleted": 0,
    "batches": 1,
    "version_conflicts": 0,
    "noops": 0,
    "retries": {
        "bulk": 0,
        "search": 0
    },
    "throttled_millis": 0,
    "requests_per_second": -1,
    "throttled_until_millis": 0,
    "failures": []
}
```

</details>

<details>
  <summary>Reindex <b>only unique</b> documents</summary>

Copy **only** documents **missing** from a destination index by setting the `op_type` option to `create`.

If a document with the same ID already exists, the operation ignores the one from the source index.<br/>
To ignore all version conflicts of documents, set the `conflicts` option to `proceed`.

> For some reason, it seems to work better if the `conflicts` option is at the start of the request's data.

```plaintext
POST _reindex
{
    "conflicts": "proceed",
    "source": {
        "index": "sourceIndex"
    },
    "dest": {
        "index": "destinationIndex",
        "op_type": "create"
    }
}
```

</details>

<details>
  <summary>Combine indexes</summary>

Combine **all** documents from one or more indexes into another by adding the source indexes as a list.

> The number of shards for your source and destination indexes **must be the same**.

```plaintext
POST _reindex
{
    "source": {
        "index": [
            "sourceIndex_1",
            "sourceIndex_2"
        ]
    },
    "dest": {
        "index": "destinationIndex"
    }
}
```

</details>

## Data streams

Data streams are **managed** indices that are highly optimised for **time-series and append-only data** (typically, logs
and observability data in general).

They work like any other index, but OpenSearch simplifies some management operations (e.g., rollovers) and stores them
in a more efficient way.

They are internally composed of multiple _backing_ indexes.<br/>
Search requests are routed to **all** backing indexes, while indexing requests are routed only to the **latest** write
index.

ISM policies allow to automatically handle index rollover or deletion.

<details>
  <summary>Create data streams</summary>

1. Create an index template containing `index_pattern: []` and `data_stream: {}`.<br/>
   This template will configure all indexes matching the defined patterns as a data stream.

   <details style="padding: 0 0 1em 1em">

   Specifying the `data_stream` object causes the template to create data streams, and not just regular indexes.

   ```plaintext
   PUT _index_template/logs-template
   {
       "data_stream": {},
       "index_patterns": [
           "logs-*"
       ]
   }
   ```

   ```json
   {
       "acknowledged": true
   }
   ```

   From here on, all indices created with a name starting for `logs-` will be data streams instead.

   By default, documents need to include a `@timestamp` field.<br/>
   One can define one's own custom timestamp field as a property of the `data_stream` object to customize this.

   ```diff
   -"data_stream": {},
   +"data_stream": {
   +    "timestamp_field": {
   +        "name": "request_time"
   +    }
   +},
   ```

   One can also add index mappings and other settings just as for regular index templates.

   </details>

1. \[optional] Explicitly create the data stream.<br/>
   Since indexes are created with the first document they ingest, if they do not exist already, the data stream can be
   created just by starting ingesting documents for the indexes matching its patterns.

   <details style="padding: 0 0 1em 1em">

   ```plaintext
   PUT _data_stream/logs-example
   ```

   ```json
   {
       "acknowledged": true
   }
   ```

   </details>

1. Start indexing documents.<br/>
   If not already existing, the data stream is created together with the index, with the first document it ingests.

   <details style="padding: 0 0 1em 1em">

   ```plaintext
   POST logs-example/_doc
   {
       "message": "login attempt failed",
       "@timestamp": "2013-03-01T00:00:00"
   }
   ```

   ```json
   {
       "_index": ".ds-logs-example-000001",
       "_id": "T_Zq9ZUBf2S2KQCqEc-d",
       "_version": 1,
       "result": "created",
       "_shards": {
           "total": 2,
           "successful": 1,
           "failed": 0
       },
       "_seq_no": 0,
       "_primary_term": 1
   }
   ```

   </details>

</details>

<details>
  <summary>Create templates for data streams</summary>

```plaintext
PUT _index_template/logs-template
{
    "data_stream": {},
    "index_patterns": [
        "logs-*"
    ]
}
```

```json
{
    "acknowledged": true
}
```

</details>

<details>
  <summary>Explicitly create data streams</summary>

```plaintext
PUT _data_stream/logs-nginx
```

```json
{
    "acknowledged": true
}
```

</details>

<details>
  <summary>Get information about data streams</summary>

```plaintext
GET _data_stream/logs-nginx
```

```json
{
    "data_streams": [
        {
            "name": "logs-nginx",
            "timestamp_field": {
                "name": "@timestamp"
            },
            "indices": [
                {
                    "index_name": ".ds-logs-nginx-000002",
                    "index_uuid": "UjUVr7haTWePKAfDz2q4Xg"
                },
                {
                    "index_name": ".ds-logs-nginx-000004",
                    "index_uuid": "gi372IUBSDO-pkaj7klLiQ"
                },
                {
                    "index_name": ".ds-logs-nginx-000005",
                    "index_uuid": "O60_VDzBStCaVGl8Sud2BA"
                }
            ],
            "generation": 5,
            "status": "GREEN",
            "template": "logs-template"
        }
    ]
}
```

</details>

<details>
  <summary>Get statistics about data streams</summary>

```plaintext
GET _data_stream/logs-nginx/_stats
```

```json
{
    "_shards": {
        "total": 2,
        "successful": 2,
        "failed": 0
    },
    "data_stream_count": 1,
    "backing_indices": 1,
    "total_store_size_bytes": 416,
    "data_streams": [
        {
            "data_stream": "logs-nginx",
            "backing_indices": 1,
            "store_size_bytes": 416,
            "maximum_timestamp": 0
        }
    ]
}
```

</details>

<details>
  <summary>Delete data streams</summary>

```plaintext
DELETE _data_stream/logs-nginx
```

```json
{
    "acknowledged": true
}
```

</details>

## Index patterns

Index patterns reference one or more indexes, data streams, or index aliases.<br/>
They are mostly used in dashboards and in the _discover_ tab to filter indexes to gather data from.

They require data to be indexed before creation.

<details>
  <summary>Create index patterns</summary>

1. Go to OpenSearch Dashboards.
1. In the _Management_ section of the side menu, select _Dashboards Management_.
1. Select _Index patterns_, then _Create index pattern_.
1. Define the pattern by entering a name in the Index pattern name field.<br/>
   Dashboards automatically adds a wildcard (`*`). It will make the pattern match multiple sources or indexes.
1. Specify the time field to use when filtering documents on a time base.<br/>
   Unless otherwise specified in the source or index properties, `@timestamp` will pop up in the dropdown menu.

   Should one **not** want to use a time filter, select that option from the dropdown menu.<br/>
   This will make OpenSearch return **all** the data in **all** the indexes that match the index pattern.

1. Select _Create index pattern_.

</details>

## APIs

OpenSearch clusters offer a REST API.<br/>
It allows almost everything - changing most settings, modify indexes, check cluster health, get statistics, etc.

One can interact with the API using every method that can send HTTP requests.<br/>
One can also send HTTP requests in the Dev Tools console in OpenSearch Dashboards. It uses a simpler syntax to format
REST requests compared to other tools like [cURL].

OpenSearch returns responses in **flat** JSON format by default.<br/>
Provide the `pretty` query parameter to obtain response bodies in human-readable form:

```sh
curl --insecure --user 'admin:someCustomStr0ng!Password' 'https://localhost:9200/_cluster/health?pretty'
awscurl --service 'es' 'https://search-domain.eu-west-1.es.amazonaws.com/_cluster/health?pretty'
```

Requests that contain a body **must** specify the `Content-Type` header, **and** provide the request's payload:

```sh
curl … \
  -H 'Content-Type: application/json' \
  -d '{"query":{"match_all":{}}}'
```

[REST API reference]

<details>
  <summary>Cluster</summary>

`/_cluster` endpoint.

  <details style="padding-left: 1rem">
    <summary>Get clusters' status</summary>

```plaintext
GET _cluster/health
```

```json
{
    "cluster_name": "opensearch-cluster",
    "status": "green",
    "timed_out": false,
    "number_of_nodes": 2,
    "number_of_data_nodes": 2,
    "discovered_master": true,
    "discovered_cluster_manager": true,
    "active_primary_shards": 9,
    "active_shards": 18,
    "relocating_shards": 0,
    "initializing_shards": 0,
    "unassigned_shards": 0,
    "delayed_unassigned_shards": 0,
    "number_of_pending_tasks": 0,
    "number_of_in_flight_fetch": 0,
    "task_max_waiting_in_queue_millis": 0,
    "active_shards_percent_as_number": 100.0
}
```

  </details>

</details>

<details>
  <summary>Documents</summary>

  <details style="padding-left: 1rem">
    <summary>Index documents</summary>

Add a JSON document to an OpenSearch index by sending a `PUT` HTTP request to the `/indexName/_doc` endpoint.

```plaintext
PUT /students/_doc/1
{
    "name": "John Doe",
    "gpa": 3.89,
    "grad_year": 2022
}
```

In the example, the document ID is specified as the student ID (`1`).<br/>
Once such a request is sent, OpenSearch creates an index called `students` if it does not exist already, and stores the
ingested document in that index.

```json
{
    "_index": "students",
    "_id": "1",
    "_version": 1,
    "result": "created",
    "_shards": {
        "total": 2,
        "successful": 2,
        "failed": 0
    },
    "_seq_no": 0,
    "_primary_term": 1
}
```

  </details>

  <details style="padding-left: 1rem">
    <summary>Search for documents</summary>

Specify the index to search for, plus a query that will be used to match documents.<br/>
The simplest query is the `match_all` query, which matches **all** documents in an index. If no search parameters are
given, the `match_all` query is assumed.

```plaintext
GET /students/_search

GET /students/_search
{
    "query": {
        "match_all": {}
    }
}
```

```json
{
    "took": 11,
    "timed_out": false,
    "_shards": {
        "total": 1,
        "successful": 1,
        "skipped": 0,
        "failed": 0
    },
    "hits": {
        "total": {
            "value": 1,
            "relation": "eq"
        },
        "max_score": 1,
        "hits": [
            {
                "_index": "students",
                "_id": "1",
                "_score": 1,
                "_source": {
                    "name": "John Doe",
                    "gpa": 3.89,
                    "grad_year": 2022
                }
            }
        ]
    }
}
```

  </details>

  <details style="padding-left: 1rem">
    <summary>Update documents</summary>

Completely, by re-indexing them:

```plaintext
PUT /students/_doc/1
{
    "name": "John Doe",
    "gpa": 3.91,
    "grad_year": 2022,
    "address": "123 Main St."
}
```

Only parts, by calling the `_update` endpoint:

```plaintext
POST /students/_update/1/
{
    "doc": {
        "gpa": 3.91,
        "address": "123 Main St."
    }
}
```

```json
{
    "_index": "students",
    "_id": "1",
    "_version": 2,
    "result": "updated",
    "_shards": {
        "total": 2,
        "successful": 2,
        "failed": 0
    },
    "_seq_no": 1,
    "_primary_term": 1
}
```

  </details>

  <details style="padding-left: 1rem">
    <summary>Delete documents</summary>

```plaintext
DELETE /students/_doc/1
```

```json
{
    "_index": "students",
    "_id": "1",
    "_version": 4,
    "result": "deleted",
    "_shards": {
        "total": 2,
        "successful": 2,
        "failed": 0
    },
    "_seq_no": 3,
    "_primary_term": 1
}
```

  </details>

</details>

<details>
  <summary>Indexes</summary>

  <details style="padding-left: 1rem">
    <summary>View the inferred field types in indexes</summary>

Send `GET` requests to the `_mapping` endpoint:

```plaintext
GET /students/_mapping
```

```json
{
    "students": {
        "mappings": {
            "properties": {
                "gpa": {
                    "type": "float"
                },
                "grad_year": {
                    "type": "long"
                },
                "name": {
                    "type": "text",
                    "fields": {
                        "keyword": {
                            "type": "keyword",
                            "ignore_above": 256
                        }
                    }
                }
            }
        }
    }
}
```

  </details>

  <details style="padding-left: 1rem">
    <summary>Create indexes specifying their mappings</summary>

```plaintext
PUT /students
{
    "settings": {
        "index.number_of_shards": 1
    },
    "mappings": {
        "properties": {
            "name": {
                "type": "text"
            },
            "grad_year": {
                "type": "date"
            }
        }
    }
}
```

```json
{
    "acknowledged": true,
    "shards_acknowledged": true,
    "index": "students"
}
```

  </details>

  <details style="padding-left: 1rem">
    <summary>Close indexes</summary>

Disables read and write operations on the impacted indexes.

```plaintext
POST /prometheus-logs-20231205/_close
```

  </details>

  <details style="padding-left: 1rem">
    <summary>(Re)Open closed indexes</summary>

Enables read and write operations on the impacted indexes.

```plaintext
POST /prometheus-logs-20231205/_open
```

  </details>

  <details style="padding-left: 1rem">
    <summary>Update indexes' settings</summary>

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

  </details>

  <details style="padding-left: 1rem">
    <summary>Delete indexes</summary>

```plaintext
DELETE /students
```

```json
{
    "acknowledged": true
}
```

  </details>

</details>

## Further readings

- [Website]
- [Codebase]
- [Documentation]
- [Lucene]
- [REST API reference]
- [Okapi BM25]
- [`fsync`][fsync]
- [AWS' managed OpenSearch]
- [Setting up Hot-Warm architecture for ISM in OpenSearch]
- [Data Prepper]

### Sources

- [What is OpenSearch?]
- [Creating a cluster]
- [Elasticsearch split brain]
- [Avoiding the Elasticsearch split brain problem, and how to recover]
- [Index templates in OpenSearch - how to use composable templates]
- [Index management]
- [Index settings]
- [Elasticsearch Index Lifecycle Management & Policy]
- [Top 14 ELK alternatives in 2024]
- [Stepping up for a truly open source Elasticsearch]
- [Managing indexes]
- [Reindex data]
- [Index templates][documentation  index templates]
- [OpenSearch Data Streams]
- [OpenSearch Indexes and Data streams]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[apis]: #apis
[data streams]: #data-streams
[hot-warm architecture]: #hot-warm-architecture
[index patterns]: #index-patterns
[index templates]: #index-templates
[indexes]: #indexes
[ingest data]: #ingest-data

<!-- Knowledge base -->
[aws' managed opensearch]: cloud%20computing/aws/opensearch.md
[curl]: curl.md

<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/opensearch-project
[creating a cluster]: https://opensearch.org/docs/latest/tuning-your-cluster/
[data prepper]: https://opensearch.org/docs/latest/data-prepper/
[documentation  index templates]: https://opensearch.org/docs/latest/im-plugin/index-templates/
[documentation]: https://opensearch.org/docs/latest/
[index management]: https://opensearch.org/docs/latest/dashboards/im-dashboards/index-management/
[index settings]: https://opensearch.org/docs/latest/install-and-configure/configuring-opensearch/index-settings/
[managing indexes]: https://opensearch.org/docs/latest/im-plugin/
[reindex data]: https://opensearch.org/docs/latest/im-plugin/reindex-data/
[rest api reference]: https://opensearch.org/docs/latest/api-reference/
[set up a hot-warm architecture]: https://opensearch.org/docs/latest/tuning-your-cluster/#advanced-step-7-set-up-a-hot-warm-architecture
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
[opensearch data streams]: https://opster.com/guides/opensearch/opensearch-machine-learning/opensearch-data-streams/
[opensearch indexes and data streams]: https://stackoverflow.com/questions/75394622/opensearch-indexes-and-data-streams#75494264
[setting up hot-warm architecture for ism in opensearch]: https://opster.com/guides/opensearch/opensearch-data-architecture/setting-up-hot-warm-architecture-for-ism/
[stepping up for a truly open source elasticsearch]: https://aws.amazon.com/blogs/opensource/stepping-up-for-a-truly-open-source-elasticsearch/
[top 14 elk alternatives in 2024]: https://signoz.io/blog/elk-alternatives/
