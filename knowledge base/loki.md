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
   1. [Logstash](#logstash)
   1. [OpenTelemetry](#opentelemetry)
1. [Labels](#labels)
   1. [Labelling best practices](#labelling-best-practices)
1. [Deployment](#deployment)
   1. [Monolithic mode](#monolithic-mode)
   1. [Simple scalable mode](#simple-scalable-mode)
   1. [Microservices mode](#microservices-mode)
1. [Object storage](#object-storage)
1. [Analytics](#analytics)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

It indexes **a set of labels** for each log stream instead of the full logs' contents.<br/>
The log data itself is then compressed and stored in chunks in object storage solutions, or locally on the host's
filesystem.

Can be executed in _single binary_ mode, with all its components running simultaneously in one process, or in
_simple scalable deployment_ mode, which groups components into read, write, and backend parts.

Files can be _index_es or _chunk_s.<br/>
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

# Run on Kubernetes in microservices mode.
helm --namespace 'loki' upgrade --create-namespace --install --cleanup-on-fail 'loki' \
  --repo 'https://grafana.github.io/helm-charts' 'loki-distributed'
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
# Verify configuration files
loki -verify-config
loki -config.file='/etc/loki/local-config.yaml' -verify-config

# List available component targets
loki -list-targets
docker run 'docker.io/grafana/loki' -config.file='/etc/loki/local-config.yaml' -list-targets

# Start server components
loki
loki -target='all'
loki -config.file='/etc/loki/config.yaml' -target='read'

# Print the final configuration to stderr and start
loki -print-config-stderr …

# Check the server is working
curl 'http://loki.fqdn:3100/ready'
curl 'http://loki.fqdn:3100/metrics'
curl 'http://loki.fqdn:3100/services'

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

### Logstash

Loki provides the `logstash-output-loki` Logstash output plugin to enable shipping logs to a Loki or Grafana Cloud
instance.<br/>
Refer [Logstash plugin].

```sh
logstash-plugin install 'logstash-output-loki'
```

```rb
output {
  loki {
    url => "http://loki.example.org:3100/loki/api/v1/push"
  }
}
```

### OpenTelemetry

See also [OpenTelemetry / OTLP].

## Labels

The content of each log line is **not** indexed. Instead, log entries are grouped into streams.<br/>
The streams are then indexed with labels.

Labels are key-value pairs, e.g.:

```plaintext
deployment_environment = development
cloud_region = us-west-1
namespace = grafana-server
```

Sets of log messages that share all the labels above would be called a _log stream_.

Loki has a default limit of 15 index labels.<br/>
I can't seem to find ways to set this up as of 2025-01-21.

When Loki performs searches, it:

1. Looks for **all** messages in the chosen stream.
1. Iterates through the logs in the stream to perform the query.

Labelling affects queries, which in turn affect dashboards.

Loki does **not** parse **nor** process log messages on ingestion.<br/>
However, some labels may automatically be applied to logs by the client that collected them.

Loki automatically tries to populate a default `service_name` label while ingesting logs.<br/>
This label is mainly used to find and explore logs in the `Explore Logs` feature of Grafana.

When receiving data from Grafana Alloy or the OpenTelemetry Collector as client, Loki automatically assigns some of the
OTel resource attributes as labels.<br/>
By default, some resource attributes will be stored as labels, with periods (.) replaced with underscores (_). The
remaining attributes are stored as structured metadata with each log entry.

_Cardinality_ is the combination of unique labels and values (how many values can each label have). It impacts the
number of log streams one creates and can lead to significant performance degradation.<br/>
Prefer fewer labels with bounded values.

Loki performs very poorly when labels have high cardinality, as it is forced to build a huge index and flush thousands
of tiny chunks to the object store.

Loki places the same restrictions on label naming as Prometheus:

- They _may_ contain ASCII letters and digits, as well as underscores and colons.<br/>
  It must match the `[a-zA-Z_:][a-zA-Z0-9_:]*` regex.
- Unsupported characters shall be converted to an underscore.<br/>
  E.g.: `app.kubernetes.io/name` shall be written as `app_kubernetes_io_name`.
- Do **not** begin **nor** end your label names with double underscores.<br/>
  This naming convention is used for internal labels, e.g. `_stream_shard_`.<br/>Internal labels are **hidden** by
  default in the label browser, query builder, and autocomplete to avoid creating confusion for users.

Prefer **not** adding labels based on the content of the log message.

Loki supports ingesting out-of-order log entries.<br/>
Out-of-order writes are enabled globally by default and can be disabled/enabled on a cluster or per-tenant basis.

Entries in a given log stream (identified by a given set of label names and values) **must be ingested in order**
within the default two hour time window.<br/>
When trying to send entries that are too old for a given log stream, Loki will respond with the `too far behind` error.

Use labels to separate streams so they can be ingested separately:

- When planning to ingest out-of-order log entries.
- For systems with different ingestion delays and shipping.

### Labelling best practices

- Use labels for things like regions, clusters, servers, applications, namespaces, and environments.

  <details>

  They will be fixed for given systems/apps and have bounded values.<br/>
  Static labels like these make it easier to query logs in a logical sense.

  </details>

- Avoid adding labels for something until you know you need it.<br/>
  Prefer using filter expressions like `|= "text"` or `|~ "regex"` to brute force logs instead.
- Ensure labels have low cardinality. Ideally, limit it to tens of values.
- Prefer using labels with long-lived values.
- Consider extracting often parsed labels from log lines on the client side by attaching it as structured metadata.
- Be aware of dynamic labels applied by clients.

## Deployment

### Monolithic mode

Runs all of Loki's microservice components inside a single process as a single binary or Docker image.

Set the `-target` command line parameter to `all`.

Useful for experimentation, or for small read/write volumes of up to approximately 20GB per day.<br/>
Recommended to use the [Simple scalable mode] if in need to scale the deployment further.

<details>
  <summary>Horizontally scale this mode to more instances</summary>

- Use a shared object store.
- Configure the `ring` section of the configuration file to share state between all instances.

</details>

<details>
  <summary>Configure high availability</summary>

- Run multiple instances setting up the `memberlist_config` configuration.
- Configure a shared object store
- Configure the `replication_factor` to `3` or more.

This will route traffic to all the Loki instances in a round robin fashion.

</details>

Query parallelization is limited by the number of instances.<br/>
Configure the `max_query_parallelism` setting in the configuration file.

### Simple scalable mode

Default configuration installed by Loki's Helm Chart and the easiest way to deploy Loki at scale.

Requires a reverse proxy to be deployed in front of Loki to direct client's API requests to either the read or write
nodes. The Loki Helm chart deploys a default reverse proxy configuration using [Nginx].

This mode can scale up to a few TBs of logs per day.<br/>
If going over this, recommended to use the [Microservices mode].

Separates execution paths into `read`, `write`, and `backend` targets.<br/>
Targets can be scaled independently.

Execution paths are activated by defining the target on Loki's startup:

- `-target=write`: the `write` target is **stateful** and controlled by a Kubernetes StatefulSet.<br/>
  Contains the [distributor] and [ingester] components.
- `-target=read`: the `read` target is **stateless** and _can_ be run as a Kubernetes Deployment.<br/>
  In the official helm chart this is currently deployed as a StatefulSet.<br/>
  Contains the [query frontend] and [querier] components.
- `-target=backend`: the `backend` target is **stateful** and controlled by a Kubernetes StatefulSet.<br/>
  Contains the [compactor], [index gateway], [query scheduler] and [ruler] components.

### Microservices mode

Runs each Loki component as its own distinct processes.<br/>
Each process is invoked specifying its own target.

Designed for Kubernetes deployments and available as the [loki-distributed] community-supported Helm chart.

Only recommended for very large Loki clusters, or when needing more precise control over them.

## Object storage

Refer [Storage] and [Loki S3 Storage: A Guide for Efficient Log Management].

<details>
  <summary>AWS example</summary>

Refer also [AWS deployment (S3 Single Store)].

  <details style="padding-left: 1em;">
    <summary>Permissions</summary>

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::<chunks-bucket-name>",
        "arn:aws:s3:::<chunks-bucket-name>/*",
        "arn:aws:s3:::<ruler-bucket-name>",
        "arn:aws:s3:::<ruler-bucket-name>/*"
      ]
    }
  ]
}
```

  </details>
  <details style="padding-left: 1em;">
    <summary>Loki settings</summary>

```yaml
storage_config:
  aws:
    region: <aws-region>
    bucketnames:  # comma-separated list
      <chunks-bucket-name>
schema_config:
  configs:
    - store: tsdb
      object_store: aws
compactor:
  delete_request_store: aws
ruler:
  storage:
    type: s3
    s3:
      region: <aws-region>
      bucketnames:  # comma-separated list
        <ruler-bucket-name>
```

  </details>
</details>

## Analytics

By default, Loki will send anonymous but uniquely-identifiable usage and configuration analytics to Grafana Labs.<br/>
Explicitly disable reporting if wanted:

```yaml
analytics:
  reporting_enabled: false
```

## Further readings

- [Website]
- [Codebase]
- [Grafana]
- [Promtail]
- [Send log data to Loki]
- [Grafana Loki store log data on S3 bucket on AWS Fargate]
- [How to install Loki on (AWS) EKS using Terraform with S3]
- [Deploy the Loki Helm chart on AWS]
- [Loki S3 Storage: A Guide for Efficient Log Management]
- [Grafana Loki Configuration Nuances]
- [OpenTelemetry / OTLP]
- [Loki-Operator]

### Sources

- [Documentation]
- [HTTP API reference]
- [How to Set Up Grafana, Loki, and Prometheus Locally with Docker Compose: Part 1 of 3]
- [Deploying Grafana, Loki, and Prometheus on AWS ECS with EFS and Cloud Formation (Part 3 of 3)]
- [AWS deployment (S3 Single Store)]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[compactor]: #compactor
[distributor]: #distributor
[index gateway]: #index-gateway
[ingester]: #ingester
[microservices mode]: #microservices-mode
[querier]: #querier
[query frontend]: #query-frontend
[query scheduler]: #query-scheduler
[ruler]: #ruler
[simple scalable mode]: #simple-scalable-mode

<!-- Knowledge base -->
[grafana]: grafana.md
[nginx]: nginx.md
[promtail]: promtail.md

<!-- Files -->
<!-- Upstream -->
[aws deployment (s3 single store)]: https://grafana.com/docs/loki/latest/configure/storage/#aws-deployment-s3-single-store
[codebase]: https://github.com/grafana/loki
[deploy the loki helm chart on aws]: https://grafana.com/docs/loki/latest/setup/install/helm/deployment-guides/aws/
[documentation]: https://grafana.com/docs/loki/latest/
[grafana loki store log data on s3 bucket on aws fargate]: https://community.grafana.com/t/grafana-loki-store-log-data-on-s3-bucket-on-aws-fargate/112861
[how to install loki on (aws) eks using terraform with s3]: https://community.grafana.com/t/how-to-install-loki-on-aws-eks-using-terraform-with-s3/136489
[http api reference]: https://grafana.com/docs/loki/latest/reference/loki-http-api/
[loki-distributed]: https://github.com/grafana/helm-charts/tree/main/charts/loki-distributed
[send log data to loki]: https://grafana.com/docs/loki/latest/send-data/
[storage]: https://grafana.com/docs/loki/latest/configure/storage/
[website]: https://grafana.com/oss/loki/
[logstash plugin]: https://grafana.com/docs/loki/latest/send-data/logstash/

<!-- Others -->
[deploying grafana, loki, and prometheus on aws ecs with efs and cloud formation (part 3 of 3)]: https://medium.com/@ahmadbilalch891/deploying-grafana-loki-and-prometheus-on-aws-ecs-with-efs-and-cloud-formation-part-3-of-3-24140ea8ccfb
[grafana loki configuration nuances]: https://medium.com/lonto-digital-services-integrator/grafana-loki-configuration-nuances-2e9b94da4ac1
[how to set up grafana, loki, and prometheus locally with docker compose: part 1 of 3]: https://medium.com/@ahmadbilalch891/how-to-set-up-grafana-loki-and-prometheus-locally-with-docker-compose-part-1-of-3-62fb25e51d92
[loki s3 storage: a guide for efficient log management]: https://last9.io/blog/loki-s3-storage-guide/
[loki-operator]: https://loki-operator.dev/
[opentelemetry / otlp]: https://loki-operator.dev/docs/open-telemetry.md/
