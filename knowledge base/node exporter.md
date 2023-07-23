# Prometheus' node exporter

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
docker run -d --name 'node-exporter' --rm \
  -p '9100:9100' --pid='host' -v '/:/host:ro,rslave' \
  'quay.io/prometheus/node-exporter:latest' --path.rootfs='/host'
sudo apt install 'prometheus-node-exporter'
```

## Further readings

- [Github]
- [Prometheus]

## Sources

All the references in the [further readings] section, plus the following:

- [Node exporter guide]

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/prometheus/node_exporter
[node exporter guide]: https://prometheus.io/docs/guides/node-exporter/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[prometheus]: prometheus.md
