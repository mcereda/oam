# Config Connector

Kubernetes addon to manage Google Cloud resources from inside Kubernetes clusters.

Provides a collection of Custom Resource Definitions and controllers.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Installation](#installation)
1. [Resources management](#resources-management)
1. [Gotchas](#gotchas)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# List gcp resources one can create using config connector.
# Requires config connector to be installed.
kubectl get crds --selector 'cnrm.cloud.google.com/managed-by-kcc=true'
```

## Installation

1. Refer to:

   - the [installation howto] for details and updated instructions if you are using GKE;
   - the [installation types] page for details and updated instructions for other K8S clusters.

1. Enable the Resource Manager API:

   ```sh
   gcloud services enable 'cloudresourcemanager.googleapis.com'
   ```

## Resources management

List what Google Cloud [resources] you can create with Config Connector:

```sh
kubectl get crds --selector cnrm.cloud.google.com/managed-by-kcc=true
```

## Gotchas

- Service accounts can be granted _editor_ access by replacing `--role="roles/owner"` with `--role="roles/editor"`; this allows **most** Config Connector functionality, except project and organization wide configurations such as IAM modifications.
- When creating a resource, Config Connector creates it if it doesn't exist; if a resource already exists with the same name, then Config Connector acquires and manages it instead.

## Further readings

- [Website]
- [Getting started]

## Sources

All the references in the [further readings] section, plus the following:

<!-- project's references -->
[getting started]: https://cloud.google.com/config-connector/docs/how-to/getting-started
[installation howto]: https://cloud.google.com/config-connector/docs/how-to/install-upgrade-uninstall
[installation types]: https://cloud.google.com/config-connector/docs/concepts/installation-types
[overview]: https://cloud.google.com/config-connector/docs/overview
[resources]: https://cloud.google.com/config-connector/docs/reference/overview
[stackdriver]: https://cloud.google.com/stackdriver/docs/solutions/gke
[website]: https://cloud.google.com/config-connector
[workload identity]: https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
<!-- external references -->
