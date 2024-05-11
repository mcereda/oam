# Monitoring solution

Leverages Prometheus and Grafana.

1. [Pre-flight operations](#pre-flight-operations)
1. [Further readings](#further-readings)

## Pre-flight operations

For example purposes, the host running them will also run the Node Exporter to provide data.<br/>
Since the Node Exporter container runs in host mode, the host's IP or FQDN must be set in [Prometheus' configuration file] for this to work.

## Further readings

- [Grafana]
- [Prometheus]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[grafana]: ../../knowledge%20base/grafana.md
[prometheus]: ../../knowledge%20base/prometheus.md

<!-- Files -->
[prometheus' configuration file]: prometheus/prometheus.yml
