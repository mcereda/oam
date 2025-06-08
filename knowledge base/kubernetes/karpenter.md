# Karpenter

Open-source, just-in-time cloud node provisioner for Kubernetes.

1. [TL;DR](#tldr)
1. [Setup](#setup)
   1. [AWS](#aws)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Runs as workload on the cluster.

Works by:

1. Watching for unschedulable pods.
1. Evaluating unschedulable pods' scheduling constraints (resource requests, node selectors, affinities, tolerations,
   and topology spread constraints).
1. Provisioning **cloud-based** nodes meeting the resource requirements and scheduling constraints of unschedulable
   pods.
1. Deleting nodes when no longer needed.

Under the hood, Karpenter adds a finalizer to the Kubernetes node object it provisions.<br/>
The finalizer blocks node deletion until all pods on it are drained and the instance is terminated.<br/>
This **only** works for nodes provisioned by Karpenter.

Should one manually delete a Karpenter-provisioned Kubernetes node object, Karpenter will gracefully cordon, drain, and
shutdown the corresponding cloud instance.

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

As of 2025-06-08, it only supports AWS and Azure nodes.<br/>
As part of the installation process, one **will** need credentials from the underlying cloud provider to allow
Karpenter-managed nodes to be started up and added to the cluster as needed.

Karpenter configuration comes in the form of:

- A _NodePool_ Custom Resource Definition.
- A _NodeClass_ Custom Resource Definition.<br/>
  Its specifics are defined by the cloud provider's implementation.

A single Karpenter NodePool is capable of handling many different pod shapes.<br/>
A cluster may have more than one NodePool.

### AWS

Leverages the [Karpenter provider for AWS].

Requirements:

- An IAM Role for Karpenter.<br/>
  Required to allow Karpenter to call AWS APIs.
- An IAM Role and an instance profile for the EC2 instances Karpenter creates.
- An EKS cluster access entry for the nodes' IAM role.<br/>
  Required by the nodes to be able to join the EKS cluster.
- An SQS queue for Karpenter.<br/>
  Required to receive Spot interruption, instance re-balance and other events.

## Further readings

- [Website]
- [Codebase]
- [Documentation]

### Sources

- [Karpenter EKS workshop]
- [Karpenter: Amazon EKS Best Practice and Cloud Cost Optimization]
- [Run Kubernetes Clusters for Less with Amazon EC2 Spot and Karpenter]
- [Karpenter best practices]

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
[Karpenter best practices]: https://docs.aws.amazon.com/eks/latest/best-practices/karpenter.html
[Karpenter EKS workshop]: https://www.eksworkshop.com/docs/autoscaling/compute/karpenter/
[Karpenter provider for AWS]: https://github.com/aws/karpenter-provider-aws
[Karpenter: Amazon EKS Best Practice and Cloud Cost Optimization]: https://catalog.us-east-1.prod.workshops.aws/workshops/f6b4587e-b8a5-4a43-be87-26bd85a70aba/en-US
[Run Kubernetes Clusters for Less with Amazon EC2 Spot and Karpenter]: https://community.aws/content/2dhlDEUfwElQ9mhtOP6D8YJbULA/run-kubernetes-clusters-for-less-with-amazon-ec2-spot-and-karpenter
