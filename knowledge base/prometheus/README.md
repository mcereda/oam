# Prometheus

Metrics gathering and alerting tool.

It collects metrics, evaluates rule expressions, displays the results, and can trigger alerts when specified conditions
are observed.

1. [TL;DR](#tldr)
1. [Components](#components)
   1. [Extras](#extras)
1. [Installation](#installation)
1. [Configuration](#configuration)
   1. [Filter metrics](#filter-metrics)
1. [Queries](#queries)
1. [Storage](#storage)
   1. [Local storage](#local-storage)
   1. [External storage](#external-storage)
   1. [Backfilling](#backfilling)
1. [Send metrics to other Prometheus servers](#send-metrics-to-other-prometheus-servers)
1. [Exporters](#exporters)
1. [Management API](#management-api)
   1. [Take snapshots of the current data](#take-snapshots-of-the-current-data)
1. [High availability](#high-availability)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

Metrics are values that measure something.

Prometheus is designed to store metrics' changes over time.

Prometheus collects metrics by:

- Actively **pulling** (_scraping_) them from configured _targets_ at given intervals.<br/>
  Targets shall expose an HTTP endpoint for Prometheus to scrape.
- Having them **pushed** to it by clients.<br/>
  This is most useful in the event the sources are behind firewalls, or otherwise prohibited from opening ports by
  security policies.

One can leverage _exporters_ collect metrics from targets that do **not** natively provide a suitable HTTP endpoint for
Prometheus to scrape from.<br/>
Exporters are small and purpose-built applications that collect their objects' metrics in different ways, then expose
them in an HTTP endpoint in their place.

<details>
  <summary>Setup</summary>

```sh
docker pull 'prom/prometheus'
docker run -p '9090:9090' -v "$PWD/config/dir:/etc/prometheus" -v 'prometheus-data:/prometheus' 'prom/prometheus'

helm repo add 'prometheus-community' 'https://prometheus-community.github.io/helm-charts' \
&& helm repo update 'prometheus-community'
helm show values 'prometheus-community/prometheus'
helm -n 'prometheus' upgrade -i --create-namespace 'prometheus' 'prometheus-community/prometheus'
kubectl -n 'prometheus' get pods -l 'app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=prometheus' \
  -o jsonpath='{.items[0].metadata.name}' \
| xargs -I '%%' kubectl -n 'prometheus' port-forward "%%" '9090'
helm --namespace 'prometheus' uninstall 'prometheus'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Start the process.
prometheus
prometheus --web.enable-admin-api

# Reload the configuration file *without* restarting the process.
kill -s 'SIGHUP' '3969'
pkill --signal 'HUP' 'prometheus'
curl -i -X 'POST' 'localhost:9090/-/reload'  # if admin APIs are enabled

# Shut down the process *gracefully*.
kill -s 'SIGTERM' '3969'
pkill --signal 'TERM' 'prometheus'
```

</details>

## Components

Prometheus is composed by its **server**, the **Alertmanager** and its **exporters**.

Alerting rules can be created within Prometheus, and configured to send custom alerts to _Alertmanager_.<br/>
Alertmanager then processes and handles the alerts, including sending notifications through different mechanisms or
third-party services.

The _exporters_ can be libraries, processes, devices, or anything else exposing metrics so that they can be scraped by
Prometheus.<br/>
Such metrics are usually made available at the `/metrics` endpoint, which allows them to be scraped directly from
Prometheus without the need of an agent.

### Extras

As a welcomed addition, [Grafana] can be configured to use Prometheus as a backend of its, in order to provide data
visualization and dashboarding functions on the data it provides.

## Installation

```sh
brew install 'prometheus'
docker run -p '9090:9090' -v './prometheus.yml:/etc/prometheus/prometheus.yml' --name prometheus -d 'prom/prometheus'
```

<details>
  <summary>Kubernetes</summary>

```sh
helm repo add 'prometheus-community' 'https://prometheus-community.github.io/helm-charts'
helm -n 'monitoring' upgrade -i --create-namespace 'prometheus' 'prometheus-community/prometheus'

helm -n 'monitoring' upgrade -i --create-namespace --repo 'https://prometheus-community.github.io/helm-charts' \
  'prometheus' 'prometheus'
```

Access components:

| Component         | From within the cluster                                   |
| ----------------- | --------------------------------------------------------- |
| Prometheus server | `prometheus-server.monitoring.svc.cluster.local:80`       |
| Alertmanager      | `prometheus-alertmanager.monitoring.svc.cluster.local:80` |
| Push gateway      | `prometheus-pushgateway.monitoring.svc.cluster.local:80`  |

```sh
# Access the prometheus server.
kubectl -n 'monitoring' get pods -l 'app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=prometheus' \
  -o jsonpath='{.items[0].metadata.name}' \
| xargs -I {} kubectl -n 'monitoring' port-forward {} 9090

# Access alertmanager.
kubectl -n 'monitoring' get pods -l 'app.kubernetes.io/name=alertmanager,app.kubernetes.io/instance=prometheus' \
  -o jsonpath='{.items[0].metadata.name}' \
| xargs -I {} kubectl -n 'monitoring' port-forward {} 9093

# Access the push gateway.
kubectl -n 'monitoring' get pods -l -l "app=prometheus-pushgateway,component=pushgateway" \
  -o jsonpath='{.items[0].metadata.name}' \
| xargs -I {} kubectl -n 'monitoring' port-forward {} 9091
```

</details>

## Configuration

The default configuration file is at `/etc/prometheus/prometheus.yml`.

```yml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: [ 'localhost:9090' ]
  - job_name: nodes
    static_configs:
      - targets:
          - fqdn:9100
          - host.local:9100
  - job_name: router
    static_configs:
      - targets: [ 'openwrt.local:9100' ]
    metric_relabel_configs:
      - source_labels: [__name__]
        action: keep
        regex: '(node_cpu)'
```

Reload the configuration with**out** restarting Prometheus's process by using the `SIGHUP` signal:

```sh
kill -s 'SIGHUP' '3969'
pkill --signal 'HUP' 'prometheus'
```

### Filter metrics

Refer [How relabeling in Prometheus works], [Scrape selective metrics in Prometheus] and
[Dropping metrics at scrape time with Prometheus].

Use [metric relabeling configurations][metric_relabel_configs] to select which series to ingest **after** scraping:

```diff
 scrape_configs:
   - job_name: router
     …
+    metric_relabel_configs:
+      - # do *not* record metrics which name matches the regex
+        # in this case, those which name starts with 'node_disk_'
+        source_labels: [ __name__ ]
+        action: drop
+        regex: node_disk_.*
   - job_name: hosts
     …
+    metric_relabel_configs:
+      - # *only* record metrics which name matches the regex
+        # in this case, those which name starts with 'node_cpu_' with cpu=1 and mode=user
+        source_labels:
+          - __name__
+          - cpu
+          - mode
+        regex: node_cpu_.*1.*user.*
+        action: keep
```

## Queries

Prometheus uses the [PromQL] query syntax.

All data is stored as time series, each one identified by a metric name (e.g., `node_filesystem_avail_bytes` for
available filesystem space).<br/>
Metrics' names can be used in query expressions to select all the time series with that name, and produce an _instant
vector_.

Time series can be filtered using _selectors_ and _labels_ (sets of key-value pairs):

```promql
node_filesystem_avail_bytes{fstype="ext4"}
node_filesystem_avail_bytes{fstype!="xfs"}
```

Square brackets allow selecting a range of samples from the current time backwards:

```promql
node_memory_MemAvailable_bytes[5m]
```

When using time ranges, the returned vector will be a _range vector_.

[Functions] can be used to build advanced queries.

<details style="padding: 0 0 1em 1em">
  <summary>Example</summary>

```promql
100 * (1 - avg by(instance)(irate(node_cpu_seconds_total{job='node_exporter',mode='idle'}[5m])))
```

![advanced query](advanced%20query%20result.png)

Labels are used to filter the job and the mode.

`node_cpu_seconds_total` returns a **counter**.<br/>
The `irate()` function calculates the **per-second rate of change** based on the last two data points of the range
interval given it as argument.

To calculate the overall CPU usage, the `idle` mode of the metric is used.

Since the idle percentage of a processor is the opposite of a busy processor, the average `irate` value is subtracted
from 1.

To make it all a percentage, the computed value is multiplied by 100.

</details>

<details>
  <summary>Query examples</summary>

```promql
# Get all allocatable CPU cores where the 'node' attribute matches regex ".*-runners-.*" grouped by node
sum(kube_node_status_allocatable_cpu_cores{node=~".*-runners-.*"}) BY (node)

# FIXME
sum(rate(container_cpu_usage_seconds_total{namespace="gitlab-runners",container="build",pod_name=~"runner.*"}[30s])) by (pod_name,container) /
sum(container_spec_cpu_quota{namespace="gitlab-runners",pod_name=~"runner.*"}/container_spec_cpu_period{namespace="gitlab-runners",pod_name=~"runner.*"}) by (pod_name,container)
```

</details>

## Storage

Refer [Storage].

Prometheus uses a **local**, **on-disk** time series database by default.<br/>
It can optionally integrate with remote storage systems.

### Local storage

Local storage is **not** clustered **nor** replicated. This makes it **not** arbitrarily scalable or durable in the face
of outages.<br/>
The use of RAID disks is suggested for storage availability, and snapshots are recommended for backups.

> The local storage is **not** intended to be durable long-term storage and external solutions should be used to achieve
> extended retention and data durability.

External storage may be used via the remote read/write APIs.<br/>
These storage systems vary greatly in durability, performance, and efficiency.

Ingested samples are grouped into blocks of **two hours**.<br/>
Each two-hours block consists of a **uniquely** named directory. This directory contains:

- A `chunks` subdirectory, hosting all the time series samples for that window of time.<br/>
  Samples are grouped into one or more segment files of up to 512 MB each by default.
- A metadata file.
- An index file.<br/>
  This indexes metric names and labels to time series in the `chunks` directory.

When series are deleted via the API, deletion records are stored in separate `tombstones` files.<br/>
Tombstone files are **not** deleted immediately from the chunk segments.

The current block for incoming samples is kept in memory and is **not** fully persisted.<br/>
This is secured against crashes by a write-ahead log (WAL) that can be replayed when the Prometheus server restarts.

Write-ahead log files are stored in the `wal` directory in segments of 128 MB in size.<br/>
These files contain raw data that has not yet been _compacted_.<br/>
Prometheus will retain a minimum of **three** write-ahead log files. Servers may retain more than these three WAL files
in order to keep at least two hours of raw data stored.

The server's `data` directory looks something like this:

```sh
./data
├── 01BKGV7JBM69T2G1BGBGM6KB12
│   └── meta.json
├── 01BKGTZQ1SYQJTR4PB43C8PD98
│   ├── chunks
│   │   └── 000001
│   ├── tombstones
│   ├── index
│   └── meta.json
├── 01BKGTZQ1HHWHV8FBJXW1Y3W0K
│   └── meta.json
├── 01BKGV7JC0RY8A6MACW02A2PJD
│   ├── chunks
│   │   └── 000001
│   ├── tombstones
│   ├── index
│   └── meta.json
├── chunks_head
│   └── 000001
└── wal
    ├── 000000002
    └── checkpoint.00000001
        └── 00000000
```

The initial two-hour blocks are eventually compacted into longer blocks in the background.<br/>
Each block will contain data spanning up to 10% of the retention time or 31 days, whichever is smaller.

The retention time defaults to **15 days**.<br/>
Expired block cleanup happens in the background. It may take up to two hours to remove expired blocks. Blocks must be
**fully** expired before they are removed.

Prometheus stores an average of 1 to 2 bytes per sample.<br/>
To plan the capacity of a Prometheus server, one can use the following rough formula:

```plaintext
needed_disk_space = retention_time_seconds * ingested_samples_per_second * bytes_per_sample
```

To lower the rate of ingested samples, one can (either-or):

- Reduce the number of scraped time series (fewer targets or fewer series per target).
- Increase the scrape interval.

Reducing the number of series is likely more effective, due to compression of samples within a series.

Should the local storage become corrupted for whatever reason, the best strategy is to shut down the Prometheus server
process, and then remove the **entire** storage directory. This does mean losing **all** the stored data.<br/>
One can alternatively try removing individual block directories or the `wal` directory to resolve the problem. Doing so
means losing approximately two hours of data per block directory.

> Prometheus does **not** support non-POSIX-compliant filesystems as local storage.<br/>
> Unrecoverable corruptions may happen.<br/>
> NFS filesystems (including AWS's EFS) are not supported as, though NFS could be POSIX-compliant, most of its
> implementations are not.<br/>
> It is strongly recommended to use a local filesystem for reliability.

If both time and size retention policies are specified, whichever triggers first will take precedence.

### External storage

TODO

### Backfilling

TODO

## Send metrics to other Prometheus servers

Also see [How to set up and experiment with Prometheus remote-write].

The remote server must accept incoming metrics.<br/>
One way is to have it start with the `--web.enable-remote-write-receiver` option.

Use the [`remote_write` setting][remote_write setting] to configure the sender to forward metrics to the receiver:

```yaml
remote_write:
  - url: http://prometheus.receiver.fqdn:9090/api/v1/write
  - url: https://aps-workspaces.eu-east-1.amazonaws.com/workspaces/ws-01234567-abcd-1234-abcd-01234567890a/api/v1/remote_write
    queue_config:
      max_samples_per_send: 1000
      max_shards: 100
      capacity: 1500
    sigv4:
      region: eu-east-1
```

## Exporters

Refer [Exporters and integrations].

Exporters are libraries and web servers that gather metrics from third-party systems, then either send them to
Prometheus servers or expose them as Prometheus metrics.

They are used in cases where it is not feasible to instrument systems to send or expose Prometheus metrics directly.

Exporters of interest:

| Exporter                               | Summary                             |
| -------------------------------------- | ----------------------------------- |
| [BOINC exporter][ordaa/boinc_exporter] | Metrics for BOINC client            |
| [Node exporter]                        | OS-related metrics                  |
| [SNMP exporter]                        | Basically SNMP in Prometheus format |

## Management API

### Take snapshots of the current data

> Requires the TSDB APIs to be enabled (`--web.enable-admin-api`).

Use the `snapshot` API endpoint to create snapshots of all current data into `snapshots/<datetime>-<rand>` under the
TSDB's data directory and return that directory as response.

It will optionally skip including data that is only present in the head block, and which has not yet been compacted to
disk.

```plaintext
POST /api/v1/admin/tsdb/snapshot
PUT /api/v1/admin/tsdb/snapshot
```

URL query parameters:

- `skip_head`=\<bool>: skip data present in the head block. Optional.

Examples:

```sh
$ curl -X 'POST' 'http://localhost:9090/api/v1/admin/tsdb/snapshot'
{
  "status": "success",
  "data": {
    "name": "20171210T211224Z-2be650b6d019eb54"
  }
}
```

The snapshot now exists at `<data-dir>/snapshots/20171210T211224Z-2be650b6d019eb54`

## High availability

Typically achieved by:

1. Running multiple Prometheus replicas.<br/>
   Replicas could each focus _on a subset_ of the whole data, or just scrape the targets multiple times and leave the
   deduplication to other tools.
1. Running a separate AlertManager instance.<br/>
   This would handle alerts from **all** the Prometheus instances, automatically managing eventually duplicated data.
1. Using tools like [Thanos], [Cortex], or Grafana's [Mimir] to aggregate and deduplicate data.
1. Directing visualizers like Grafana to the aggregator instead of the Prometheus replicas.

## Further readings

- [Website]
- [Codebase]
- [Documentation]
- [Helm chart]
- [`docker/monitoring`][docker/monitoring]
- [Grafana]
- [High Availability for Prometheus and Alertmanager: An Overview]
- [Making Prometheus Highly Available (HA) & Scalable with Thanos]
- [Scaling Prometheus with Cortex]
- [Prometheus Definitive Guide Part I - Metrics and Use Cases]
- [Prometheus Definitive Guide Part II - Prometheus Query Language]
- [Prometheus Definitive Guide Part III - Prometheus Operator]
- [Cortex]
- [Thanos]
- Grafana's [Mimir]
- [Exporters and integrations]

### Sources

- [Getting started with Prometheus]
- [How I monitor my OpenWrt router with Grafana Cloud and Prometheus]
- [Scrape selective metrics in Prometheus]
- [Dropping metrics at scrape time with Prometheus]
- [How relabeling in Prometheus works]
- [Install Prometheus and Grafana with helm 3 on a local machine VM]
- [Set up prometheus and ingress on kubernetes]
- [How to integrate Prometheus and Grafana on Kubernetes using Helm]
- [How to set up and experiment with Prometheus remote-write]
- [Install Prometheus and Grafana by Helm]
- [Prometheus and Grafana setup in Minikube]
- [I need to know about the below kube_state_metrics description. Exactly looking is what the particular metrics doing]
- [High Availability in Prometheus: Best Practices and Tips]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[cortex]: ../cortex.md
[grafana]: ../grafana.md
[mimir]: ../mimir.md
[node exporter]: node%20exporter.md
[snmp exporter]: snmp%20exporter.md
[thanos]: ../thanos.md

<!-- Files -->
[docker/monitoring]: ../../docker%20compositions/monitoring/README.md

<!-- Upstream -->
[codebase]: https://github.com/prometheus/prometheus
[documentation]: https://prometheus.io/docs/
[Exporters and integrations]: https://prometheus.io/docs/instrumenting/exporters/
[functions]: https://prometheus.io/docs/prometheus/latest/querying/functions/
[helm chart]: https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus
[metric_relabel_configs]: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#metric_relabel_configs
[promql]: https://prometheus.io/docs/prometheus/latest/querying/basics/
[remote_write setting]: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write
[storage]: https://prometheus.io/docs/prometheus/latest/storage/
[website]: https://prometheus.io/

<!-- Others -->
[dropping metrics at scrape time with prometheus]: https://www.robustperception.io/dropping-metrics-at-scrape-time-with-prometheus/
[getting started with prometheus]: https://opensource.com/article/18/12/introduction-prometheus
[high availability for prometheus and alertmanager: an overview]: https://promlabs.com/blog/2023/08/31/high-availability-for-prometheus-and-alertmanager-an-overview/
[high availability in prometheus: best practices and tips]: https://last9.io/blog/high-availability-in-prometheus/
[how i monitor my openwrt router with grafana cloud and prometheus]: https://grafana.com/blog/2021/02/09/how-i-monitor-my-openwrt-router-with-grafana-cloud-and-prometheus/
[how relabeling in prometheus works]: https://grafana.com/blog/2022/03/21/how-relabeling-in-prometheus-works/
[how to integrate prometheus and grafana on kubernetes using helm]: https://semaphoreci.com/blog/prometheus-grafana-kubernetes-helm
[how to set up and experiment with prometheus remote-write]: https://developers.redhat.com/articles/2023/11/30/how-set-and-experiment-prometheus-remote-write
[i need to know about the below kube_state_metrics description. exactly looking is what the particular metrics doing]: https://stackoverflow.com/questions/60440847/i-need-to-know-about-the-below-kube-state-metrics-description-exactly-looking-i#60449570
[install prometheus and grafana by helm]: https://medium.com/@at_ishikawa/install-prometheus-and-grafana-by-helm-9784c73a3e97
[install prometheus and grafana with helm 3 on a local machine vm]: https://dev.to/ko_kamlesh/install-prometheus-grafana-with-helm-3-on-local-machine-vm-1kgj
[making prometheus highly available (ha) & scalable with thanos]: https://www.infracloud.io/blogs/thanos-ha-scalable-prometheus/
[ordaa/boinc_exporter]: https://gitlab.com/ordaa/boinc_exporter
[prometheus and grafana setup in minikube]: http://blog.marcnuri.com/prometheus-grafana-setup-minikube/
[prometheus definitive guide part i - metrics and use cases]: https://www.infracloud.io/blogs/prometheus-architecture-metrics-use-cases/
[prometheus definitive guide part ii - prometheus query language]: https://www.infracloud.io/blogs/promql-prometheus-guide/
[prometheus definitive guide part iii - prometheus operator]: https://www.infracloud.io/blogs/prometheus-operator-helm-guide/
[scaling prometheus with cortex]: https://www.infracloud.io/blogs/cortex-for-ha-monitoring-with-prometheus/
[scrape selective metrics in prometheus]: https://docs.last9.io/docs/how-to-scrape-only-selective-metrics-in-prometheus
[set up prometheus and ingress on kubernetes]: https://blog.gojekengineering.com/diy-how-to-set-up-prometheus-and-ingress-on-kubernetes-d395248e2ba
