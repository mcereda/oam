# Cluster autoscaler

Automatically adjusts the number of nodes in Kubernetes clusters.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Acts when one of the following conditions is true:

- Pods failed to run in the cluster due to insufficient resources.
- Nodes in the cluster have been underutilized for an extended period of time, and their pods can be placed on other
  existing nodes.

<details>
  <summary>Setup</summary>

```sh
helm repo add 'autoscaler' 'https://kubernetes.github.io/autoscaler'
helm show values 'autoscaler/cluster-autoscaler'

helm install 'cluster-autoscaler' 'autoscaler/cluster-autoscaler' --set 'autoDiscovery.clusterName'=clusterName
helm --namespace 'kube-system' upgrade --install 'cluster-autoscaler' 'autoscaler/cluster-autoscaler' \
  --set 'autoDiscovery.clusterName'=clusterName

helm uninstall 'cluster-autoscaler'
helm --namespace 'kube-system' uninstall 'cluster-autoscaler'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<details>
  <summary>Real world use cases</summary>

```sh
helm --namespace 'kube-system' upgrade --install 'cluster-autoscaler' 'autoscaler/cluster-autoscaler' \
  --set 'cloudProvider'='aws' --set 'awsRegion'='eu-west-1' \
  --set 'autoDiscovery.clusterName'='defaultCluster' --set 'rbac.serviceAccount.name'='cluster-autoscaler-aws'
```

</details>

## Further readings

- [Main repository]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[main repository]: https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler

<!-- Others -->
