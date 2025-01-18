# Distributed APplication Runtime

Portable, event-driven runtime for building distributed applications across cloud and edge.

1. [TL;DR](#tldr)
1. [Self-hosted mode](#self-hosted-mode)
1. [Clustered mode](#clustered-mode)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Codifies standards and best practices for building microservice applications into _building block_ APIs.<br/>
Provides _cross-cutting_ APIs that apply across all the build blocks.<br/>
Exposes its HTTP and gRPC APIs as a sidecar architecture to avoid requiring the application to include any Dapr-related
runtime code.

Building blocks:

- Consist of an HTTP or gRPC API that can be called from one's code to use one or more Dapr components.
- Enable building portable applications using the language and framework of one's choice.
- Are independent from one another.
- Have no limit to how many you use in one's application.

Dapr can be executed:

- [Self-hosted][self-hosted mode] on a Windows/Linux/macOS machine, e.g. for local development.
- [Clustered][clustered mode] on Kubernetes or clusters of physical or virtual machines, e.g. for production.

<details>
  <summary>Setup</summary>

```sh
brew install 'dapr/tap/dapr-cli'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Launch a sidecar for a blank application named 'myApp' that will listen on port '3500'.
dapr run --app-id 'myApp' --dapr-http-port '3500'

```

</details>

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Self-hosted mode

Dapr runs as a separate sidecar process **for each** service.<br/>
This sidecar can be called via HTTP or gRPC to use state stores, pub/sub, binding components, and the other building
blocks.

Use the Dapr CLI to run Dapr-enabled applications on one's local machine.

```sh
brew install 'dapr/tap/dapr-cli'
dapr init
```

This:

- Fetches and installs the Dapr sidecar binaries locally.
- Creates a development environment to streamline application development with Dapr.

The development environment includes:

- Running a Redis container as a local state store and message broker.
- Running a Zipkin container for observability.
- Creating a default components folder with component definitions for the above.
- Running a Dapr placement service container for local actor support.
- Running a Dapr scheduler service container for job scheduling.

## Clustered mode

<details>
  <summary>In Kubernetes</summary>

Dapr runs as a sidecar container alongside the application container in the same pod by using the
`dapr-sidecar-injector` and `dapr-operator` control plane services.

The `dapr-sentry` service acts as a certificate authority to enable mutual TLS between Dapr sidecar instances.<br/>
This provides secure data encryption as well as providing identity via [Spiffe].

</details>

<details>
  <summary>On clusters of machines</summary>

Dapr's control plane services can be deployed in high availability mode to machines.

Dapr uses multicast DNS by default to provide name resolution via DNS for the applications running in the cluster.<br/>
This can be optionally replaced by Hashicorp's Consul.

</details>

## Further readings

- [Website]
- [Codebase]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[clustered mode]: #clustered-mode
[self-hosted mode]: #self-hosted-mode

<!-- Knowledge base -->
[spiffe]: ../spiffe.md

<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/dapr/dapr
[documentation]: https://docs.dapr.io/
[website]: https://dapr.io/

<!-- Others -->
