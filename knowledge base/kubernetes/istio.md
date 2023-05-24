# Istio

> Last information check done on 2020-10-26.

## Table of contents <!-- omit in toc -->

1. [What it is](#what-it-is)
1. [What is it for](#what-is-it-for)
1. [How it works](#how-it-works)
1. [Installation](#installation)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## What it is

ELI5, Istio is a way to control how different microservices can communicate with one another, with them being parts of an application that share data or just isolated services depending on others.

Istio is really a dedicated network overlay for applications to run on top of, better know as a _service mesh_. In a service mesh, requests are routed between microservices through proxies in their own infrastructure layer, where a sidecar proxy sits alongside a microservice and routes requests to other proxies.<br/>
Without a service mesh, each microservice needs to be coded with logic to govern service-to-service communication, which means developers are less focused on business goals. It also means communication failures are harder to diagnose because the logic that governs interservice communication is hidden within each service.

## What is it for

- automatic load balancing for HTTP, gRPC, WebSocket, and TCP traffic
- fine-grained control of traffic behavior with rich routing rules, retries, failovers, and fault injection
- access controls, rate limits and quotas
- metrics, logs, and traces for all traffic within a cluster, including cluster ingress and egress
- secure service-to-service communication in a cluster with strong identity-based authentication and authorization

## How it works

Each microservice will have all its traffic routed through a proxy (the `istio-proxy`) sidecar, which is nothing more than an extended `envoy` container. Those are the only Istio components that interact with traffic in what is called the _Data Plane_.

Such sidecars are controlled (managed, configured) by Istio's _Control Plane_, and provide the control plane with metrics, tracing, logging and other information.

## Installation

See the [getting started guide] for more information.

1. download and extract the **latest** release for x86_64

   ```sh
   curl -L 'https://istio.io/downloadIstio' | sh -
   ```

   or specify the version and/or architecture if you need

   ```sh
   curl -L 'https://istio.io/downloadIstio' | ISTIO_VERSION='1.6.8' TARGET_ARCH='x86_64' sh -
   ```

1. add `istioctl` to your _PATH_ if you need it

   ```sh
   cd "istio-${ISTIO_VERSION}"
   export PATH="${PWD}/bin:${PATH}"
   ```

1. install istio using a profile to set it up (_demo_ is for testing, but others are available)

   ```sh
   istioctl install --set profile=demo
   ```

1. add the label to instruct Istio to automatically inject Envoy sidecar proxies when you deploy your application later

   ```sh
   kubectl label namespace 'default' 'istio-injection=enable'
   ```

## Further readings

- Istio's [getting started guide]

## Sources

All the references in the [further readings] section, plus the following:

- Red Hat's article on [service meshes][service mesh]

<!-- project's references -->
[getting started guide]: https://istio.io/latest/docs/setup/getting-started/

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
<!-- external references -->
[service mesh]: https://www.redhat.com/en/topics/microservices/what-is-a-service-mesh
