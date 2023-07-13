# Grafana

Open-source platform for monitoring and observability.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Provisioning](#provisioning)
   1. [Datasources](#datasources)
   1. [Dashboards](#dashboards)
1. [Dashboards of interest](#dashboards-of-interest)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Export all existing dashboards by ID.
curl -sS \
  -H 'Authorization: Basic YWRtaW46YWRtaW4=' \
  'http://grafana:3000/api/search' \
| jq -r '.[].uid' - \
| parallel " \
    curl -sS \
      -H 'Authorization: Basic YWRtaW46YWRtaW4=' \
      'http://grafana:3000/api/dashboards/uid/{}' \
    > '{}.json' \
  "
```

## Provisioning

See [provision dashboards and data sources] for details.

### Datasources

Data sources can be managed automatically at provisioning by adding YAML configuration files in the `provisioning/datasources` directory.

Each configuration file can contain a list of `datasources` to add or update during startup.<br/>
If the data source already exists, Grafana reconfigures it to match the provisioned configuration file.

Grafana also deletes the data sources listed in `deleteDatasources` before adding or updating those in the `datasources` list.

```yml
---
apiVersion: 1
datasources:
  - id: 1
    name: Prometheus
    orgId: 1
    uid: a17feb01-a0c1-432e-8ef5-7b277cb0b32b
    type: prometheus
    typeName: Prometheus
    typeLogoUrl: public/app/plugins/datasource/prometheus/img/prometheus_logo.svg
    access: proxy
    url: http://prometheus:9090
    user: ''
    database: ''
    basicAuth: false
    isDefault: true
    jsonData:
      httpMethod: POST
    readOnly: false
```

The easiest way to write datasources definitions in the configuration file is to:

1. Login to Grafana as `admin`
1. Manually setup the datasource
1. Issue a `GET /api/datasources` request to Grafana's API to get the datasource configuration
   ```sh
   curl -sS 'http://grafana:3000/api/datasources' -H 'Authorization: Basic YWRtaW46YWRtaW4='
   ```
1. Edit it as YAML
1. Drop the YAML definition into the `provisioning/datasources` directory

```sh
$ curl -sS 'http://grafana:3000/api/datasources' -H 'Authorization: Basic YWRtaW46YWRtaW4=' \
| yq -y '{apiVersion: 1, datasources: .}' - \
| tee '/etc/grafana/provisioning/datasources/default.yml'
apiVersion: 1
datasources:
  - id: 1
    uid: a17feb01-a0c1-432e-8ef5-7b277cb0b32b
    orgId: 1
    name: Prometheus
    type: prometheus
    typeName: Prometheus
    typeLogoUrl: public/app/plugins/datasource/prometheus/img/prometheus_logo.svg
    access: proxy
    url: http://rpi4b.lan:9090
    user: ''
    database: ''
    basicAuth: false
    isDefault: true
    jsonData:
      httpMethod: POST
    readOnly: true
```

### Dashboards

Dashboards can be automatically managed by adding one or more YAML config files in the `provisioning/dashboards` directory.<br/>
Each config file can contain a list of dashboards `providers` that load dashboards into Grafana from the local filesystem.

When Grafana starts, it will insert all dashboards available in the configured path, or update them if they are already present.<br/>
Later on it will poll that path every `updateIntervalSeconds`, look for updated json files and update/insert those into the database.

```yml
apiVersion: 1
providers:
  - name: dashboards
    folder: ''
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: false
    options:
      path: /var/lib/grafana/dashboards
      foldersFromFilesStructure: true
```

Save existing dashboards like [you would for the datasources][datasources provisioning].<br/>
Save the dashboard definitions in JSON files in the path searched by the provider (e.g. `/var/lib/grafana/dashboards`).

```sh
$ curl -sS \
  -H 'Authorization: Basic YWRtaW46YWRtaW4=' \
  'http://grafana:3000/api/search' \
| jq -r '.[].uid' - \
| parallel " \
    curl -sS \
      -H 'Authorization: Basic YWRtaW46YWRtaW4=' \
      'http://grafana:3000/api/dashboards/uid/{}' \
    > '/var/lib/grafana/dashboards/{}.json' \
  "
```

## Dashboards of interest

| Name               | Grafana ID | URLs                                                                                                                                                                                           |
| ------------------ | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Node exporter full | 1860       | [grafana](https://grafana.com/grafana/dashboards/1860-node-exporter-full/), [github raw](https://raw.githubusercontent.com/rfmoz/grafana-dashboards/master/prometheus/node-exporter-full.json) |

## Further readings

- [Website]
- [Github]
- [HTTP API reference]
- [Prometheus]
- [`docker/monitoring`][docker/monitoring]

## Sources

All the references in the [further readings] section, plus the following:

- [Provisioning]
- [Provision dashboards and data sources]
- [Data source on startup]

<!--
  References
  -->

<!-- Upstream -->
[data source on startup]: https://community.grafana.com/t/data-source-on-startup/8618/2
[github]: https://github.com/grafana/grafana
[http api reference]: https://grafana.com/docs/grafana/latest/developers/http_api/
[provision dashboards and data sources]: https://grafana.com/tutorials/provision-dashboards-and-data-sources/
[provisioning]: https://grafana.com/docs/grafana/latest/administration/provisioning/
[website]: https://grafana.com

<!-- In-article sections -->
[datasources provisioning]: #datasources
[further readings]: #further-readings

<!-- Knowledge base -->
[prometheus]: prometheus.md

<!-- Files -->
[docker/monitoring]: ../docker/monitoring/README.md
