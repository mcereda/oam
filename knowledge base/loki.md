# Grafana Loki

Horizontally scalable, highly available, multi-tenant log aggregation system inspired by Prometheus and designed to be
very cost-effective and easy to operate.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

It indexes **a set of labels** for each log stream instead of the full logs' contents.

Needs agents or other clients to push logs to the server.

Supports object storage solutions.

<details>
  <summary>Setup</summary>

```sh
# Install via package repository.
apt install 'loki'
dnf install 'loki'

# Run via Docker.
docker run --name loki -d \
  -p '3100:3100' -v "$(pwd)/config/loki.yml:/etc/loki/config.yml:ro" \
  'grafana/loki:3.3.2' -config.file='/etc/loki/config.yml'
```

Default configuration file for package-based installations is `/etc/loki/config.yml`.

</details>

<details>
  <summary>Usage</summary>

```sh
# Check the server is working
curl 'http://loki.fqdn:3100/ready'
curl 'http://loki.fqdn:3100/metrics'
```

</details>

## Further readings

- [Website]
- [Codebase]
- [Grafana]
- [Promtail]

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
[website]: https://grafana.com/oss/loki/

<!-- Others -->
