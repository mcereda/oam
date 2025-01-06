# Promtail

> TODO

Agent shipping the contents of **local** logs (e.g. files, systemd's journal, k8s pods) to some Grafana Loki instance.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Comes packaged with [Loki] releases.

<details>
  <summary>Setup</summary>

```sh
# Install via package repository.
apt install 'promtail'
dnf install 'promtail'

# Run via Docker.
docker run --name 'promtail' -d \
  -p '9080:9080' -v "$(pwd)/config/promtail.yml:/etc/promtail/config.yml:ro" \
  'grafana/promtail:3.3.2' -config.file='/etc/promtail/config.yml'
```

Default configuration file for package-based installations is `/etc/promtail/config.yml`.

</details>

<details>
  <summary>Usage</summary>

```sh
# Do a test run
promtail -dry-run -config.file '/etc/promtail/config.yml'

# Check the server is working
curl 'http://promtail.fqdn:9080/ready'
curl 'http://promtail.fqdn:9080/metrics'

# Connect to the web server
open 'http://promtail.fqdn:9080/'
```

</details>

## Further readings

- [Codebase]
- [Grafana]
- [Loki]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[grafana]: grafana.md
[loki]: loki.md

<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/grafana/loki
[documentation]: https://grafana.com/docs/loki/latest/send-data/promtail/

<!-- Others -->
