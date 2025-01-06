# Karpenter

Open-source, just-in-time cloud node provisioner for Kubernetes.

1. [TL;DR](#tldr)
1. [Setup](#setup)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Karpenter works by:

1. Watching for unschedulable pods.
1. Evaluating unschedulable pods' scheduling constraints (resource requests, node selectors, affinities, tolerations,
   and topology spread constraints).
1. Provisioning **cloud-based** nodes meeting the requirements of unschedulable pods.
1. Deleting nodes when no longer needed.

Karpenter runs as workload on the cluster.

Should one manually delete a Karpenter-provisioned node, Karpenter will gracefully cordon, drain, and shutdown the
corresponding instance.<br/>
Under the hood, Karpenter adds a finalizer to the node object it provisions. This blocks deletion until all pods are
drained and the instance is terminated. This **only** works for nodes provisioned by Karpenter.

<details>
  <summary>Setup</summary>

```sh
# Managed NodeGroups
helm --namespace 'kube-system' upgrade --create-namespace \
  --install 'karpenter' 'oci://public.ecr.aws/karpenter/karpenter' --version '1.1.1' \
  --set 'settings.clusterName=myCluster' \
  --set 'settings.interruptionQueue=myCluster' \
  --set 'controller.resources.requests.cpu=1' \
  --set 'controller.resources.requests.memory=1Gi' \
  --set 'controller.resources.limits.cpu=1' \
  --set 'controller.resources.limits.memory=1Gi' \
  --wait

# Fargate
# As per the managed NodeGroups, but with a serviceAccount annotation
helm … \
  --set 'serviceAccount.annotations."eks.amazonaws.com/role-arn"=arn:aws:iam::012345678901:role/myCluster-karpenter'
```

</details>

<!-- Uncomment if used
<details>
  <summary>Usage</summary>

```sh
```

</details>
-->

<!-- Uncomment if used
<details>
  <summary>Real world use cases</summary>

```sh
```

</details>
-->

## Setup

Karpenter's controller and webhook deployment are designed to run as a workload on the cluster.

As of 2024-12-24, it only supports AWS and Azure nodes.<br/>
As part of the installation process, one **will** need credentials from the underlying cloud provider to allow
Karpenter-managed nodes to be started up and added to the cluster as needed.

## Further readings

- [Website]
- [Codebase]
- [Documentation]

### Sources

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/aws/karpenter-provider-aws
[documentation]: https://karpenter.sh/docs/
[website]: https://karpenter.sh/

<!-- Others -->
