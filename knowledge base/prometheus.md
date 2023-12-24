# Prometheus

Monitoring and alerting system that collects metrics from configured targets at given intervals, evaluates rule expressions, displays the results, and can trigger alerts when specified conditions are observed.<br/>
Metrics can also be pushed using plugins, in the event hosts are behind a firewall or prohibited from opening ports by security policy.

## Table of contents <!-- omit in toc -->

1. [Components](#components)
   1. [Extras](#extras)
1. [Configuration](#configuration)
1. [Queries](#queries)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Components

Prometheus is composed by its **server**, the **Alertmanager** and its **exporters**.

Alerting rules can be created within Prometheus, and configured to send custom alerts to _Alertmanager_.<br/>
Alertmanager then processes and handles the alerts, including sending notifications through different mechanisms or third-party services.

The _exporters_ can be libraries, processes, devices, or anything else exposing metrics so that they can be scraped by Prometheus.<br/>
Such metrics are usually made available at the `/metrics` endpoint, which allows them to be scraped directly from Prometheus without the need of an agent.

### Extras

As welcomed addition, [Grafana] can be configured to use Prometheus as a backend of its in order to provide data visualization and dashboarding functions on the data it provides.

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
```

## Queries

Prometheus' query syntax is [PromQL].

All data is stored as time series, each one identified by a metric name, e.g. `node_filesystem_avail_bytes` for available filesystem space.<br/>
Metrics' names can be used in the expressions to select all of the time series with this name and produce an **instant vector**.

Time series can be filtered using selectors and labels (sets of key-value pairs):

```promql
node_filesystem_avail_bytes{fstype="ext4"}
node_filesystem_avail_bytes{fstype!="xfs"}
```

Square brackets allow to select a range of samples from the current time backwards:

```promql
node_memory_MemAvailable_bytes[5m]
```

When using time ranges, the vector returned will be a **range vector**.

[Functions] can be used to build advanced queries:

```promql
100 * (1 - avg by(instance)(irate(node_cpu_seconds_total{job='node_exporter',mode='idle'}[5m])))
```

![advanced query](prometheus%20advanced%20query.png)

Labels are used to filter the job and the mode. `node_cpu_seconds_total` returns a **counter**, and the irate() function calculates the **per-second rate of change** based on the last two data points of the range interval.<br/>
To calculate the overall CPU usage, the idle mode of the metric is used. Since idle percent of a processor is the opposite of a busy processor, the irate value is subtracted from 1. To make it a percentage, it is multiplied by 100.

## Further readings

- [Website]
- [Github]
- [`docker/monitoring`][docker/monitoring]
- [Node exporter]
- [SMNP exporter]
- [`ordaa/boinc_exporter`][ordaa/boinc_exporter]
- [Grafana]

## Sources

All the references in the [further readings] section, plus the following:

- [Getting started with Prometheus]
- [Node exporter guide]
- [SNMP monitoring and easing it with Prometheus]
- [`prometheus/node_exporter`][prometheus/node_exporter]
- [`prometheus/snmp_exporter`][prometheus/snmp_exporter]
- [How I monitor my OpenWrt router with Grafana Cloud and Prometheus]

<!--
  References
  -->

<!-- Upstream -->
[functions]: https://prometheus.io/docs/prometheus/latest/querying/functions/
[github]: https://github.com/prometheus/prometheus
[node exporter guide]: https://prometheus.io/docs/guides/node-exporter/
[prometheus/node_exporter]: https://github.com/prometheus/node_exporter
[prometheus/snmp_exporter]: https://github.com/prometheus/snmp_exporter
[promql]: https://prometheus.io/docs/prometheus/latest/querying/basics/
[website]: https://prometheus.io/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[grafana]: grafana.md
[node exporter]: node%20exporter.md
[snmp exporter]: snmp%20exporter.md

<!-- Files -->
[docker/monitoring]: ../docker/monitoring/README.md

<!-- Others -->
[getting started with prometheus]: https://opensource.com/article/18/12/introduction-prometheus
[how i monitor my openwrt router with grafana cloud and prometheus]: https://grafana.com/blog/2021/02/09/how-i-monitor-my-openwrt-router-with-grafana-cloud-and-prometheus/
[ordaa/boinc_exporter]: https://gitlab.com/ordaa/boinc_exporter
[snmp monitoring and easing it with prometheus]: https://medium.com/@openmohan/snmp-monitoring-and-easing-it-with-prometheus-b157c0a42c0c
