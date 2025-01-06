# Cluster autoscaler

Automatically adjusts the number of nodes in Kubernetes clusters to meet their current needs.

1. [TL;DR](#tldr)
1. [Best practices](#best-practices)
1. [Troubleshooting](#troubleshooting)
   1. [Unschedulable pods do not trigger scale-up](#unschedulable-pods-do-not-trigger-scale-up)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

The purpose of Cluster Autoscaler is to get pending pods a place to run on.

The autoscaler acts when one of the following conditions is true:

- Pods failed to run in the cluster due to insufficient resources.<br/>
  This triggers a scale-**up** event, where it will try to **add** a new node.
- Nodes in the cluster have been consistently underutilized for a significant amount of time, and their pods can be
  moved on other existing nodes.<br/>
  This triggers a scale-**down** event, where it will try to **remove** an existing node.

The time required for node provisioning depends on the cloud provider and other Kubernetes components.

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

<details>
  <summary>Real world use cases</summary>

```sh
aws eks --region 'eu-west-1' update-kubeconfig --name 'custom-eks-cluster' \
&& helm --namespace 'kube-system' upgrade --install --repo 'https://kubernetes.github.io/autoscaler' \
  'cluster-autoscaler' 'cluster-autoscaler' \
  --set 'cloudProvider'='aws' --set 'awsRegion'='eu-west-1' --set 'autoDiscovery.clusterName'='custom-eks-cluster' \
  --set 'rbac.serviceAccount.name'='cluster-autoscaler-aws' \
  --set 'replicaCount'='2' \
  --set 'resources.requests.cpu'='40m' --set 'resources.requests.memory'='50Mi' \
  --set 'resources.limits.cpu'='100m' --set 'resources.limits.memory'='300Mi' \
  --set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight'='100' \
  --set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.topologyKey'='kubernetes.io/hostname' \
  --set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].key'='app.kubernetes.io/name' \
  --set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].operator'='In' \
  --set 'affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].values[0]'='aws-cluster-autoscaler'
```

</details>

## Best practices

- Do **not** modify nodes belonging to autoscaled node groups directly.
  Changes will be soon lost as the modified nodes might be deleted at any time.
- All nodes within the same autoscaled node group should have the same capacity, labels and system pods running on them.
- Specify resource requests for all the pods one can, so that nodes can be scaled more reliably.
- Should one need to prevent pods from being deleted too abruptly, consider using PodDisruptionBudgets.
- Check one's cloud provider's VM quota is big enough **before** specifying min/max settings for clusters' node pools.
- Ensure **any** additional node group autoscaler (**especially** those from one's own cloud provider) are **not**
  competing for resources.<br/>
- Prefer **avoiding** running multiple node autoscalers if possible.

## Troubleshooting

### Unschedulable pods do not trigger scale-up

#### Context  <!-- omit in toc -->

As of 2025-01-06, at least with EKS, it easily happens that unschedulable pods that would normally trigger a scale-up
stay unschedulable and cause the _pod didn't trigger scale-up_ event instead.

This primarily happens when the cluster's node groups are updated for any reason.

#### Solution  <!-- omit in toc -->

Restarting the Cluster Autoscaler's pods worked most of the time.

It seems to be some sort of issue with cache.

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
