# Grafana

Open-source platform for monitoring and observability.

1. [TL;DR](#tldr)
1. [Setup](#setup)
1. [Provisioning](#provisioning)
   1. [Datasources](#datasources)
   1. [Dashboards](#dashboards)
1. [Dashboards of interest](#dashboards-of-interest)
1. [Alerting](#alerting)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

<details>
  <summary>Usage</summary>

```sh
docker run -d --rm --name 'grafana-oss' -p '3000:3000' 'grafana/grafana-oss'
docker run -d --rm --name 'grafana-enterprise' -p '3000:3000' -ti -entrypoint 'bash' 'grafana/grafana-enterprise'
```

```plaintext
# Return health information
GET /api/health
```

</details>

<details>
  <summary>Real world use cases</summary>

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

</details>

## Setup

<details>
  <summary>Kubernetes</summary>

```sh
helm repo add 'grafana' 'https://grafana.github.io/helm-charts'
helm -n 'monitoring' upgrade -i --create-namespace --set adminPassword='abc0123' 'grafana' 'grafana/grafana'

helm -n 'monitoring' upgrade -i --create-namespace --repo 'https://grafana.github.io/helm-charts' 'grafana' 'grafana'
```

Access components:

| Component | From within the cluster                   |
| --------- | ----------------------------------------- |
| Server    | `grafana.monitoring.svc.cluster.local:80` |

```sh
# Access the server
kubectl -n 'monitoring' get secret 'grafana' -o jsonpath='{.data.admin-password}' | base64 --decode
kubectl -n 'monitoring' get pods -l 'app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana' \
  -o jsonpath='{.items[0].metadata.name}' \
| xargs -I '%%' kubectl -n 'monitoring' port-forward "%%" '3000'
```

Clean up:

```sh
helm -n 'monitoring' delete 'grafana'
kubectl delete namespace --ignore-not-found 'monitoring'
```

Access Prometheus instances in the same namespace using `http://prometheus-server`

</details>

## Provisioning

See [provision dashboards and data sources] for details.

### Datasources

Data sources can be managed automatically at provisioning by adding YAML configuration files in the
`provisioning/datasources` directory.

Each configuration file can contain a list of `datasources` to add or update during startup.<br/>
If the data source already exists, Grafana reconfigures it to match the provisioned configuration file.

Grafana also deletes the data sources listed in `deleteDatasources` before adding or updating those in the `datasources`
list.

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

Dashboards can be automatically managed by adding one or more YAML config files in the `provisioning/dashboards`
directory.<br/>
Each config file can contain a list of dashboards `providers` that load dashboards into Grafana from the local
filesystem.

When Grafana starts, it will insert all dashboards available in the configured path, or update them if they are already
present.<br/>
Later on it will poll that path every `updateIntervalSeconds`, look for updated json files and update/insert those into
the database.

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

| Name                            | Grafana ID | URLs                                                                                                                                                                                           |
| ------------------------------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Node exporter full              | 1860       | [grafana](https://grafana.com/grafana/dashboards/1860-node-exporter-full/), [github raw](https://raw.githubusercontent.com/rfmoz/grafana-dashboards/master/prometheus/node-exporter-full.json) |
| OpenWRT                         | 11147      | [grafana](https://grafana.com/grafana/dashboards/11147-openwrt/)                                                                                                                               |
| prometheus 2.0 overview         | 3662       | FIXME                                                                                                                                                                                          |
| kubernetes cluster (prometheus) | 6417       | FIXME                                                                                                                                                                                          |
| Nextcloud                       | 9632       | FIXME                                                                                                                                                                                          |

## Alerting

Refer [alerting] and [Get started with Grafana Alerting].

1. Create a contact point if not existing already.
1. Create an alert rule.

## Further readings

- [Website]
- [Github]
- [Documentation]
- [HTTP API reference]
- [Prometheus]
- [docker compositions/monitoring]
- Official [helm chart]
- [Loki]
- [Get started with Grafana Alerting]

## Sources

All the references in the [further readings] section, plus the following:

- [Provisioning]
- [Provision dashboards and data sources]
- [Data source on startup]
- [Set up prometheus and ingress on kubernetes]
- [How to integrate Prometheus and Grafana on Kubernetes using Helm]
- [Alerting]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[datasources provisioning]: #datasources
[further readings]: #further-readings

<!-- Knowledge base -->
[loki]: loki.md
[prometheus]: prometheus/README.md

<!-- Files -->
[docker compositions/monitoring]: ../docker%20compositions/monitoring/README.md

<!-- Upstream -->
[alerting]: https://grafana.com/docs/grafana/latest/alerting/
[data source on startup]: https://community.grafana.com/t/data-source-on-startup/8618/2
[documentation]: https://grafana.com/docs/grafana/latest/
[get started with grafana alerting]: https://grafana.com/tutorials/alerting-get-started/
[github]: https://github.com/grafana/grafana
[helm chart]: https://github.com/grafana/helm-charts/tree/main/charts/grafana
[http api reference]: https://grafana.com/docs/grafana/latest/developers/http_api/
[provision dashboards and data sources]: https://grafana.com/tutorials/provision-dashboards-and-data-sources/
[provisioning]: https://grafana.com/docs/grafana/latest/administration/provisioning/
[website]: https://grafana.com

<!-- Others -->
[how to integrate prometheus and grafana on kubernetes using helm]: https://semaphoreci.com/blog/prometheus-grafana-kubernetes-helm
[set up prometheus and ingress on kubernetes]: https://blog.gojekengineering.com/diy-how-to-set-up-prometheus-and-ingress-on-kubernetes-d395248e2ba
