# Grafana's Mimir

Metrics aggregator.

Allows ingesting [Prometheus] or OpenTelemetry metrics, run queries, create new data through the use of recording rules,
and set up alerting rules across multiple tenants to leverage tenant federation.

<!-- Remove this line to uncomment if used
## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Setup](#setup)
   1. [Monolithic mode](#monolithic-mode)
   1. [Microservices mode](#microservices-mode)
1. [Storage](#storage)
   1. [Object storage](#object-storage)
1. [APIs](#apis)
1. [Deduplication of data from multiple Prometheus scrapers](#deduplication-of-data-from-multiple-prometheus-scrapers)
1. [Migrate to Mimir](#migrate-to-mimir)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Scrapers (like Prometheus or Grafana's Alloy) need to send metrics data to Mimir.<br/>
Mimir will **not** scrape metrics itself.

Mimir listens by default on port `8080` for HTTP and on port `9095` for GRPC.

Mimir stores time series in TSDB blocks, that are uploaded to an object storage bucket.<br/>
Such blocks are the same that Prometheus and Thanos use, though each application stores blocks in different places and
uses slightly different metadata files for them.

Mimir supports multiple tenants, and stores blocks on a **per-tenant** level.<br/>
When multi-tenancy is **disabled**, it will only manage a single tenant going by the name `anonymous`.

Blocks can be uploaded using the `mimirtool` utility, so that Mimir can access them.<br/>
Mimir **will** perform some sanitization and validation of each block's metadata.

```sh
mimirtool backfill --address='http://mimir.example.org' --id='anonymous' 'block_1' … 'block_N'
```

As a result of validation, Mimir will probably reject Thanos' blocks due to unsupported labels.<br/>
As a workaround, upload Thanos' blocks directly to Mimir's blocks bucket, using the `<tenant>/<block ID>/` prefix.

<details>
  <summary>Setup</summary>

```sh
docker pull 'grafana/mimir'

mimir
docker run --rm --name 'mimir' --publish '8080:8080' --publish '9095:9095' 'grafana/mimir'

mimir --config.file='./demo.yaml'
docker run --rm --name 'mimir' --publish '8080:8080' --publish '9095:9095' \
  --volume "$PWD/config.yaml:/etc/mimir/config.yaml" \
  'grafana/mimir' --config.file='/etc/mimir/config.yaml'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Get help.
mimir -help
mimir -help-all

# Validate configuration files
mimir -modules -config.file 'path/to/config.yaml'

# See the current configuration of components
GET /config
GET /runtime_config

# See changes in the runtime configuration from the default one
GET /runtime_config?mode=diff

# Check the service is ready
# A.K.A. readiness probe
GET /ready

# Get metrics
GET /metrics
```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Setup

Mimir's configuration file is YAML-based.<br/>
There is no default configuration file, but it _can_ be specified on launch.

```sh
mimir --config.file='./demo.yaml'

docker run --rm --name 'mimir' --publish '8080:8080' --publish '9095:9095' \
  --volume "$PWD/config.yaml:/etc/mimir/config.yaml" \
  'grafana/mimir' --config.file='/etc/mimir/config.yaml'
```

Refer [Grafana Mimir configuration parameters] for the available parameters.

If enabled, environment variable references can be used in the configuration file to set values that need to be
configurable during deployment.<br/>
This feature is enabled on the command line via the `-config.expand-env=true` option.

Each variable reference is replaced at startup by the value of the environment variable.<br/>
The replacement is case-**sensitive**, and occurs **before** the YAML file is parsed.<br/>
References to undefined variables are replaced by empty strings unless a default value or custom error text is
specified.

Use the `${VAR}` placeholder, optionally specifying a default value with `${VAR:default_value}`, where `VAR` is the name
of the environment variable and `default_value` is the value to use if the environment variable is undefined.

Configuration files can be stored gz-compressed. In this case, add a `.gz` extension to those files that should be
decompressed before parsing.

Mimir loads a given configuration file at startup. This configuration **cannot** be modified at runtime.

Mimir supports _secondary_ configuration files that define the _runtime_'s configuration.<br/>
This configuration is reloaded **dynamically**. It allows to change the runtime configuration without having to restart
Mimir's components or instance.

Runtime configuration must be **explicitly** enabled, either on launch or in the configuration file under
`runtime_config`.<br/>
If multiple runtime configuration files are specified, they will be **merged** left to right.<br/>
Mimir reloads the contents of these files every 10 seconds.

```sh
mimir … -runtime-config.file='path/to/file/1,path/to/file/N'
```

It only encompasses a **subset** of the whole configuration that was set at startup, but its values take precedence over
command-line options.

Some settings are repeated for multiple components.<br/>
To avoid repetition in the configuration file, set them up in the `common` configuration file section or give them to
Mimir using the `-common.*` CLI options.<br/>
Common settings are applied to all components first, then the components' specific configurations override them.

Settings are applied as follows, with each one applied later overriding the previous ones:

1. YAML common values
1. YAML specific values
1. CLI common flags
1. CLI specific flags

Specific configuration for one component that is passed to other components is simply ignored by those.<br/>
This makes it safe to reuse files.

Mimir can be deployed in one of two modes:

- _Monolithic_, which runs all required components in a single process.
- _Microservices_, where components are run as distinct processes.

The deployment mode is determined by the `-target` option given to Mimir's process.

Whatever the Mimir's deployment mode, it will need to receive data from other applications.<br/>
It will **not** scrape metrics itself.

<details style="padding: 0 0 1rem 0">
<summary>Prometheus configuration</summary>

```yaml
remote_write:
  - url: http://mimir.example.org:9009/api/v1/push
```

</details>

[Grafana] considers Mimir a data source of type _Prometheus_, and must be [provisioned](grafana.md#datasources)
accordingly.<br/>
From there, metrics can be queried in Grafana's _Explore_ tab, or can populate dashboards that use Mimir as their data
source.

### Monolithic mode

Runs **all** required components in a **single** process.

Can be horizontally scaled out by deploying multiple instances of Mimir's binary, all of them started with the
`-target=all` option.

```mermaid
graph LR
  r(Reads)
  w(Writes)
  lb(Load Balancer)
  m1(Mimir<br/>instance 1)
  mN(Mimir<br/>instance N)
  os(Object Storage)

  r --> lb
  w --> lb
  lb --> m1
  lb --> mN
  m1 --> os
  mN --> os
```

### Microservices mode

Mimir's components are deployed as distinct processes.<br/>
Each process is invoked with its own `-target` option set to a specific component (i.e., `-target='ingester'` or
`-target='distributor'`).

```mermaid
graph LR
  r(Reads)
  qf(Query Frontend)
  q(Querier)
  sg(Store Gateway)
  w(Writes)
  d(Distributor)
  i(Ingester)
  os(Object Storage)
  c(Compactor)

  r --> qf --> q --> sg --> os
  w --> d --> i --> os
  os <--> c
```

**Every** required component **must** be deployed in order to have a working Mimir instance.

This mode is the preferred method for production deployments, but it is also the most complex.<br/>
Recommended using Kubernetes and the [`mimir-distributed` Helm chart][helm chart].

Each component scales up independently.<br/>
This allows for greater flexibility and more granular failure domains.

## Storage

Mimir supports the `s3`, `gcs`, `azure`, `swift`, and `filesystem` backends.<br/>
`filesystem` is the default one.

### Object storage

Refer [Configure Grafana Mimir object storage backend].

Blocks storage must be located under a **different** prefix or bucket than both the ruler's and AlertManager's stores.
Mimir **will** fail to start if that is the case.

To avoid that, it is suggested to override the `bucket_name` setting in the specific configurations:

```yaml
common:
  storage:
    backend: s3
    s3:
      endpoint: s3.us-east-2.amazonaws.com
      region: us-east-2

blocks_storage:
  s3:
    bucket_name: mimir-blocks

alertmanager_storage:
  s3:
    bucket_name: mimir-alertmanager

ruler_storage:
  s3:
    bucket_name: mimir-ruler
```

## APIs

Refer [Grafana Mimir HTTP API].

## Deduplication of data from multiple Prometheus scrapers

Refer [Configure Grafana Mimir high-availability deduplication].

## Migrate to Mimir

Refer [Migrate from Thanos or Prometheus to Grafana Mimir].

## Further readings

- [Website]
- [Codebase]
- [Prometheus]
- [Grafana]

Alternatives:

- [Cortex]
- [Thanos]

### Sources

- [Documentation]
- [Migrate from Thanos or Prometheus to Grafana Mimir]
- [Configure Grafana Mimir object storage backend]
- [Grafana Mimir configuration parameters]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[cortex]: cortex.md
[grafana]: grafana.md
[prometheus]: prometheus.md
[thanos]: thanos.md

<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/grafana/mimir
[configure grafana mimir high-availability deduplication]: https://grafana.com/docs/mimir/latest/configure/configure-high-availability-deduplication/
[configure grafana mimir object storage backend]: https://grafana.com/docs/mimir/latest/configure/configure-object-storage-backend/
[documentation]: https://grafana.com/docs/mimir/latest/
[grafana mimir configuration parameters]: https://grafana.com/docs/mimir/latest/configure/configuration-parameters/
[grafana mimir http api]: https://grafana.com/docs/mimir/latest/references/http-api/
[helm chart]: https://github.com/grafana/mimir/tree/main/operations/helm/charts/mimir-distributed
[migrate from thanos or prometheus to grafana mimir]: https://grafana.com/docs/mimir/latest/set-up/migrate/migrate-from-thanos-or-prometheus/
[website]: https://grafana.com/oss/mimir/

<!-- Others -->
