# Metrics server

Cluster-wide addon component collecting and aggregating resource metrics pulled from each kubelet.<br/>
Serves metrics using Metrics API for use by HPA, VPA, and by the `kubectl top` command.

It is a reference implementation of the Metrics API.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Fetches resource metrics from all kubelets, then exposes them in the API server.

Uses the Kubernetes API to track nodes and pods, and queries each node over HTTP to fetch metrics.<br/>
Builds an internal view of pod metadata, and keeps a cache of pod health.<br/>
The cached pod information is available via the extension API that the metrics-server makes available.

Calls the kubelet API to collect metrics from each node.<br/>
Depending on the metrics-server version it uses:

- The metrics resource endpoint `/metrics/resource` in version v0.6.0+, or
- The summary API endpoint `/stats/summary` in older versions.

<details>
  <summary>Setup</summary>

```sh
kubectl apply -f 'https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml'
helm -n 'kube-system' upgrade --install --repo 'https://kubernetes-sigs.github.io/metrics-server' \
  'metrics-server' 'metrics-server' \
  --set 'replicas'='2' --set 'addonResizer.enabled'='true' \
  --set 'containerPort'='10251' \
  --set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight'='100' \
  --set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.topologyKey'='kubernetes.io/hostname' \
  --set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].key'='app.kubernetes.io/name' \
  --set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].operator'='In' \
  --set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].values[0]'='metrics-server'
```

</details>

## Further readings

- [Website]
- [Main repository]

### Sources

- [Helm chart]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[helm chart]: https://artifacthub.io/packages/helm/metrics-server/metrics-server
[main repository]: https://github.com/kubernetes-sigs/metrics-server
[website]: https://kubernetes.io/docs/tasks/debug/debug-cluster/resource-metrics-pipeline/
