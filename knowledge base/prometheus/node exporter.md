# Prometheus' node exporter

TODO

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

- [Codebase]
- [Prometheus]

### Sources

- [Node exporter guide]
- [Helm chart values]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[prometheus]: README.md

<!-- Upstream -->
[codebase]: https://github.com/prometheus/node_exporter
[helm chart values]: https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-node-exporter
[node exporter guide]: https://prometheus.io/docs/guides/node-exporter/
