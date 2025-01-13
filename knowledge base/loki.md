# Grafana Loki

Horizontally scalable, highly available, multi-tenant log aggregation system inspired by Prometheus and designed to be
very cost-effective and easy to operate.

1. [TL;DR](#tldr)
1. [Components](#components)
   1. [Distributor](#distributor)
   1. [Ingester](#ingester)
   1. [Query frontend](#query-frontend)
   1. [Query scheduler](#query-scheduler)
   1. [Querier](#querier)
   1. [Index gateway](#index-gateway)
   1. [Compactor](#compactor)
   1. [Ruler](#ruler)
1. [Clients](#clients)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

It indexes **a set of labels** for each log stream instead of the full logs' contents.<br/>
The log data itself is then compressed and stored in chunks in object storage solutions, or locally on the host's
filesystem.

Loki can be executed in _single binary_ mode, with all its components running simultaneously in one process, or in
_simple scalable deployment_ mode, which groups components into read, write, and backend parts.

Loki's files can be _index_es or _chunk_s.<br/>
Indexes are tables of contents in TSDB format of where to find logs for specific sets of labels.<br/>
Chunks are containers for log entries for specific sets of labels.

Needs agents or other clients to collect and push logs to the Loki server.

<details>
  <summary>Setup</summary>

```sh
# Install via package repository.
apt install 'loki'
dnf install 'loki'
zypper install 'loki'

# Run via Docker.
docker run --name loki -d \
  -p '3100:3100' -v "$(pwd)/config/loki.yml:/etc/loki/config.yml:ro" \
  'grafana/loki:3.3.2' -config.file='/etc/loki/config.yml'
```

Default configuration file for package-based installations is `/etc/loki/config.yml` or `/etc/loki/loki.yaml`.

  <details style="padding: 0 0 1em 1em;">
    <summary>Disable reporting</summary>

  ```yaml
  analytics:
    reporting_enabled: false
  ```

  </details>

</details>

<details>
  <summary>Usage</summary>

```sh
# Check the server is working.
curl 'http://loki.fqdn:3100/ready'
curl 'http://loki.fqdn:3100/metrics'

# Check components in Loki clusters are up and running.
# Such components must run by themselves for this.
# The read component returns ready when browsing to <http://localhost:3101/ready>.
curl 'http://loki.fqdn:3101/ready'
# The write component returns ready when browsing to <http://localhost:3102/ready>.
curl 'http://loki.fqdn:3102/ready'
```

</details>

## Components

### Distributor

Handles incoming push requests from clients.

Once it receives a set of streams in an HTTP request, validates each stream for correctness and to ensure the stream is
within the configured tenant (or global) limits.<br/>
Each **valid** stream is sent to `n` ingesters in parallel, with `n` being the replication factor for the data.

The distributor determines the ingesters to which send a stream to by using consistent hashing.

A load balancer **must** sit in front of the distributor to properly balance incoming traffic to them.<br/>
In Kubernetes, this is provided by the internal service load balancer.

The distributor is stateless and can be properly scaled.

### Ingester

On the _write_ path, persists data and ships it to long-term storage.<br/>
On the _read_ path, returns recently ingested, in-memory log data for queries.

Ingesters contain a lifecycle subcomponent managing their own lifecycle in the hash ring.<br/>
Each ingester has a state, which can be one of `PENDING`, `JOINING`, `ACTIVE`, `LEAVING`, or `UNHEALTHY`:

- `PENDING`: the ingester is waiting for a handoff from another ingester in the `LEAVING` state.<br/>
  This only applies for legacy deployment modes.
- `JOINING`: the ingester is currently inserting its tokens into the ring and initializing itself.<br/>
  It **may** receive write requests for tokens it owns.
- `ACTIVE`: the ingester is fully initialized.<br/>
  It may receive both write and read requests for tokens it owns.
- `LEAVING`: the ingester is shutting down.<br/>
  It may receive read requests for data it still has in memory.
- `UNHEALTHY`: the ingester has failed to heartbeat.<br/>
  Set by the distributor when periodically checking the ring.

Chunks are compressed and marked as read-only when:

- The current chunk has reached the configured capacity.
- Too much time has passed without the current chunk being updated.
- A flush occurs.

Whenever a chunk is compressed and marked as read-only, a writable chunk takes its place.

If an ingester crashes or exits abruptly, all the data that has not yet been flushed **will be lost**.<br/>
Replicas of each log mitigate this risk.

When flushes occur to a persistent storage provider, the chunk in question is hashed based on its tenant, labels, and
contents. Multiple ingesters with the same copy of the data will **not** write the same data to the backing store twice,
but if any write failed to one of the replicas, multiple differing chunk objects **will** be created in the backing
store.

### Query frontend

**Optional** service providing the querier's API endpoints.<br/>
Can be used to accelerate the _read_ path.

When in place, incoming query requests should be directed to the query frontend instead of the queriers.<br/>
The querier service will **still** be required within the cluster in order to actually execute the queries.

Performs some query adjustments, and holds queries in an internal queue.<br/>
Queriers will act as workers to pull jobs from the queue, execute them, and return them to the query frontend for
aggregation. They **will** need to be configured with the query frontend address to allow for connection.

Query frontends are stateless and can be properly scaled.

### Query scheduler

**Optional** service providing more advanced queuing functionality than the query frontend.<br/>
When active, the query frontend pushes split up queries to the query scheduler, which in turn enqueues them in an
internal in-memory queue.

Each tenant will get its own queue to guarantee fairness across all tenants.

Queriers connecting to the query scheduler will act as workers to pull jobs from the queue, execute them, and return
them to the query frontend for aggregation. They **will** need to be configured with the query scheduler address to
allow for connection.

Query schedulers are stateless and can be properly scaled.

### Querier

Executes Log Query Language (LogQL) queries.

Handles HTTP requests from the client directly, or pulls subqueries from the query frontend or query scheduler if
configured to do so.

Fetches log data from both the ingesters and from long-term storage.<br/>
They query **all** ingesters for in-memory data before falling back and run the same query against the backend store.

Because of the replication factor, it **is** possible for the querier to receive duplicate data.<br/>
To take care of this, it internally deduplicates data with the same nanosecond timestamp, label set, and log message.

### Index gateway

Used only by _shipper stores_.

Handles and serves metadata queries.<br/>
Those are queries that look up data from the index.

Query frontends will query the index gateway to know the log volume of queries, so to make a decision on how to shard
the queries.<br/>
The queriers will query the index gateway to know the chunk references for a given query, so to know which chunks to
fetch.

The index gateway can run in _simple_ or _ring_ mode:

- In _simple_ mode, each index gateway instance serves all indexes from all tenants.
- In _ring_ mode, index gateways use a consistent hash ring to distribute and shard the indexes per tenant amongst
  available instances.

### Compactor

Used by _shipper stores_ to compact multiple index files, produced by the ingesters and shipped to object storage, into
single index files per day and tenant.

It:

- Downloads files from object storage at regular intervals.
- Merges downloaded files into a single one.
- Uploads the newly created index.
- Cleans up the old files.

Also manages log retention and log deletion.

### Ruler

Manages and evaluates rules and alert expressions provided in rule configurations.<br/>

Rule configurations are stored in object storage or local file system.<br/>
They can be managed through the ruler's API, or directly by uploading them to object storage.

Rulers _can_ delegate rule evaluation to the query frontends to gain the advantages of query splitting, query sharding,
and caching offered by the query frontend.

Multiple rulers will use a consistent hash ring to distribute rule groups amongst available ruler instances.

## Clients

Refer [Send log data to Loki].

## Further readings

- [Website]
- [Codebase]
- [Grafana]
- [Promtail]
- [Send log data to Loki]

### Sources

- [Documentation]
- [HTTP API reference]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[grafana]: grafana.md
[promtail]: promtail.md

<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/grafana/loki
[documentation]: https://grafana.com/docs/loki/latest/
[http api reference]: https://grafana.com/docs/loki/latest/reference/loki-http-api/
[send log data to loki]: https://grafana.com/docs/loki/latest/send-data/
[website]: https://grafana.com/oss/loki/

<!-- Others -->
