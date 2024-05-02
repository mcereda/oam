# Elastic Kubernetes Service

1. [TL;DR](#tldr)
1. [Requirements](#requirements)
1. [Creation procedure](#creation-procedure)
1. [Create worker nodes](#create-worker-nodes)
   1. [Create managed node groups](#create-managed-node-groups)
   1. [Schedule pods on Fargate](#schedule-pods-on-fargate)
1. [Access management](#access-management)
1. [Secrets encryption through KMS](#secrets-encryption-through-kms)
1. [Storage](#storage)
1. [Troubleshooting](#troubleshooting)
   1. [Identify common issues](#identify-common-issues)
   1. [The worker nodes fail to join the cluster](#the-worker-nodes-fail-to-join-the-cluster)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

When one creates a [_cluster_][amazon eks clusters], one really only creates the cluster's control plane and the
dedicated nodes underneath it.<br/>
Worker nodes can consist of any combination of [self-managed nodes], [managed node groups] and [Fargate], and depend on
the control plane.

EKS automatically installs some [self-managed add-ons][amazon eks add-ons] like the AWS VPC CNI plugin, `kube-proxy` and
CoreDNS.<br/>
Disable them in the cluster's definition.

Upon cluster creation, EKS
[automatically creates a security group][amazon eks security group requirements and considerations] and applies it to
both the control plane and nodes.<br/>
Such security group cannot be avoided nor customized in the cluster's definition (e.g. using IaC tools like [Pulumi] or
[Terraform]):

> ```txt
> error: aws:eks/cluster:Cluster resource 'cluster' has a problem: Value for unconfigurable attribute. Can't configure a value for "vpc_config.0.cluster_security_group_id": its value will be decided automatically based on the result of applying this configuration.
> ```

For some reason, giving resources a tag like `aks:eks:cluster-name=value` succeeds, but has no effect (it is not really
applied).

By default, the IAM principal creating the cluster is the only one able to make calls to the cluster's API server.<br/>
To let other IAM principals have access to the cluster, one needs to add them to it. See [access management].

<details>
  <summary>Usage</summary>

```sh
# Create clusters.
aws eks create-cluster \
  --name 'DeepThought' \
  --role-arn 'arn:aws:iam::000011112222:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS' \
  --resources-vpc-config 'subnetIds=subnet-11112222333344445,subnet-66667777888899990'
aws eks create-cluster … --access-config 'authenticationMode=API'

# Check cluster's authentication mode.
aws eks describe-cluster --name 'DeepThought' --query 'cluster.accessConfig.authenticationMode' --output 'text'

# Change encryption configuration.
aws eks associate-encryption-config \
  --cluster-name 'DeepThought' \
  --encryption-config '[{
    "provider": { "keyArn": "arn:aws:kms:eu-west-1:000011112222:key/33334444-5555-6666-7777-88889999aaaa" },
    "resources": [ "secrets" ]
  }]'


# Create access entries to use IAM for authentication.
aws eks create-access-entry --cluster-name 'DeepThought' \
  --principal-arn 'arn:aws:iam::000011112222:role/Admin'
aws eks create-access-entry … --principal-arn 'arn:aws:iam::000011112222:user/bob'

# List available access policies.
aws eks list-access-policies

# Associate policies to access entries.
aws eks associate-access-policy --cluster-name 'DeepThought' \
  --principal-arn 'arn:aws:iam::000011112222:role/Admin' \
  --policy-arn 'arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy' \
  --access-scope '[ "type": "cluster" ]'

# Connect to clusters.
aws eks update-kubeconfig --name 'DeepThought' && kubectl cluster-info


# Create EC2 node groups.
aws eks create-nodegroup \
  --cluster-name 'DeepThought' \
  --nodegroup-name 'alpha' \
  --scaling-config 'minSize=1,maxSize=3,desiredSize=1' \
  --node-role-arn 'arn:aws:iam::000011112222:role/DeepThinkerNodeRole' \
  --subnets 'subnet-11112222333344445' 'subnet-66667777888899990'

# Create Fargate profiles.
aws eks create-fargate-profile \
  --cluster-name 'DeepThought' \
  --fargate-profile-name 'alpha' \
  --pod-execution-role-arn 'arn:aws:iam::000011112222:role/DeepThinkerFargate' \
  --subnets 'subnet-11112222333344445' 'subnet-66667777888899990' \
  --selectors 'namespace=string'
```

</details>

<!-- Uncomment if needed
<details>
  <summary>Real world use cases</summary>
</details>
-->

## Requirements

- \[suggestion] 1 (one) custom _Cluster Service Role_ with the `AmazonEKSClusterPolicy` IAM policy attached or similar
  custom permissions.

  <details style="margin-bottom: 1em;">

  Kubernetes clusters managed by EKS make calls to other AWS services on the user's behalf to manage the resources that
  the cluster uses.<br/>
  For a cluster to be allowed to make those calls, it **requires** to have the aforementioned permissions.

  To create clusters which would **not** require access to any other AWS resource, one can assign the cluster the
  `AWSServiceRoleForAmazonEKS` service-linked role directly <sup>[1][service-linked role permissions for amazon eks],
  [2][amazon eks cluster iam role]</sup>.

  > Amazon EKS uses the service-linked role named `AWSServiceRoleForAmazonEKS` - The role allows Amazon EKS to manage
  > clusters in your account. The attached policies allow the role to manage the following resources: network
  > interfaces, security groups, logs, and VPCs.
  >
  > ---
  >
  > Prior to October 3, 2023, [AmazonEKSClusterPolicy] was required on the IAM role for each cluster.
  >
  > Prior to April 16, 2020, [AmazonEKSServicePolicy] was also required and the suggested name was `eksServiceRole`.
  > With the `AWSServiceRoleForAmazonEKS` service-linked role, that policy is no longer required for clusters created on
  > or after April 16, 2020.

  <div class="tip" style="
    background-color: rgba(0,255,0,0.0625);
    border: solid lightGreen;  /* #90EE90 */
    margin: 1em 0;
    padding: 1em 1em 0;
  ">
  <header style="font-weight: bold; margin-bottom: 0.5em">Pro tip</header>

  Should one want to use more advanced features like [encryption with managed keys][secrets encryption through kms], the
  role will need access to the referenced resources.<br/>
  In this case it would probably be better to create a custom role instead of assigning permissions to the built-in one.

  </div>

  </details>

- \[suggestion] 1+ (one or more) custom service role(s) for the pod executors, with the required policies attached or
  similar permissions.

  The reasons and required permissions vary depending on the type of executor.<br/>
  It would probably be better to create a custom role instead of assigning permissions to the built-in one.

  See the corresponding section under [Create worker nodes].

- 1+ (one or more) executor(s) for pods.<br/>
  See the [Create worker nodes] section.

- \[if using APIs for authentication] 1+ (one or more) access entry (/entries) with an EKS access policy assigned.

- _Private_ clusters have [more special requirements][private cluster requirements] of their own.

## Creation procedure

The Internet is full of guides and abstractions which do not work, are confusing, or rely on other code.<br/>
Some create Cloudformation stacks in the process. Follow the
[Getting started guide][getting started with amazon eks - aws management console and aws cli] to avoid issues.

This is what worked:

1. Create a VPC, if one does not have them already, with public and private subnets that meet
   [EKS' requirements][amazon eks vpc and subnet requirements and considerations].

   [Example in Cloudformation](https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml)

1. Create a custom IAM role for the cluster if needed (see [Requirements]).<br/>
1. Attach the required policies to the role used in the cluster.

   <details>
     <summary>Example in CLI</summary>

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [{
           "Effect": "Allow",
           "Action": "sts:AssumeRole",
           "Principal": {
               "Service": "eks.amazonaws.com"
           }
       }]
   }
   ```

   ```sh
   aws iam create-role \
     --role-name 'DeepThinker' \
     --assume-role-policy-document 'file://eks-cluster-role-trust-policy.json'
   aws iam attach-role-policy \
     --role-name 'DeepThinker' \
     --policy-arn 'arn:aws:iam::aws:policy/AmazonEKSClusterPolicy'
   ```

   </details>

   <details style="margin-bottom: 1em;">
     <summary>Example in Pulumi</summary>

   ```ts
   const cluster_assumeRole_policy = JSON.stringify({
       Version: "2012-10-17",
       Statement: [{
           Effect: "Allow",
           Action: "sts:AssumeRole",
           Principal: {
               Service: "eks.amazonaws.com",
           },
       }],
   });

   const cluster_service_role = new aws.iam.Role("cluster-service-role", {
       assumeRolePolicy: cluster_assumeRole_policy,
       managedPolicyArns: [
           // alternatively, use RolePolicyAttachments
           "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
       ],
       name: "DeepThinker",
       …
   });
   ```

   </details>

1. Create the cluster.<br/>
   Make sure you give it the correct cluster service role.

   <details>
     <summary>Example in CLI</summary>

   ```sh
   aws eks create-cluster \
     --name 'DeepThought' \
     --role-arn 'arn:aws:iam::000011112222:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS' \
     --resources-vpc-config 'subnetIds=subnet-11112222333344445,subnet-66667777888899990'
   ```

   </details>

   <details style="margin-bottom: 1em;">
     <summary>Example in Pulumi</summary>

   ```ts
   const cluster = new aws.eks.Cluster("cluster", {
       name: "DeepThought",
       roleArn: cluster_service_role.arn,
       vpcConfig: {
           subnetIds: [
               "subnet-11112222333344445",
               "subnet-66667777888899990",
           ],
       },
       …
   });
   ```

   </details>

1. [Give access to users][access management].
1. Connect to the cluster.

   ```sh
   $ aws eks update-kubeconfig --name 'DeepThought'
   Added new context arn:aws:eks:eu-east-1:000011112222:cluster/DeepThought to /home/itsAme/.kube/config

   $ kubectl cluster-info
   Kubernetes control plane is running at https://FB32A9C4A3D6BBC82695B1936BF4AAA3.gr7.eu-east-1.eks.amazonaws.com
   CoreDNS is running at https://FB32A9C4A3D6BBC82695B1936BF4AAA3.gr7.eu-east-1.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
   ```

1. [Create some worker nodes][create worker nodes].
1. Profit!

## Create worker nodes

See [step 3](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html#eks-launch-workers) of the
[getting started guide][getting started with amazon eks - aws management console and aws cli].

### Create managed node groups

See [Choosing an Amazon EC2 instance type] and [Managed node groups] for more information.

Additional requirements:

- \[suggestion] 1 (one) custom _Node Service Role_ with the `AmazonEKSWorkerNodePolicy`,
  `AmazonEC2ContainerRegistryReadOnly` and `AmazonEKS_CNI_Policy` policies attached or similar permissions.

  The EKS nodes' `kubelet` makes calls to the AWS APIs on one's behalf.<br/>
  Nodes receive permissions for these API calls through an IAM instance profile and associated policies.

  For a node to be allowed to make those calls, it **requires** to have the aforementioned permissions.

- When deploying a managed node group in **private** subnets, one must ensure that it can access Amazon ECR for pulling
  container images.<br/>
  Do this by connecting a NAT gateway to the route table of the subnet, or by adding the following AWS PrivateLink VPC
  endpoints:

  - Amazon ECR API endpoint interface: `com.amazonaws.{region}.ecr.api`.
  - Amazon ECR Docker registry API endpoint interface: `com.amazonaws.{region}.ecr.dkr`.
  - Amazon S3 gateway endpoint: `com.amazonaws.{region}.s3`.

- If the nodes are to be created in private subnets, the cluster
  [**must** provide its private API server endpoint][private cluster requirements].<br/>
  Set the cluster's `vpc_config.0.endpoint_private_access` attribute to `true`.

Procedure:

1. Create a custom IAM role for the nodes if needed (see [Requirements]).
1. Attach the required policies to the role used by the nodes.

   <details>
     <summary>Example in CLI</summary>

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": "sts:AssumeRole",
               "Principal": {
                   "Service": "ec2.amazonaws.com"
               }
           }
       ]
   }
   ```

   ```sh
   aws iam create-role \
     --role-name 'DeepThinkerNode' \
     --assume-role-policy-document 'file://eks-node-role-trust-policy.json'
   aws iam attach-role-policy \
     --policy-arn 'arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy' \
     --role-name 'DeepThinkerNode'
   aws iam attach-role-policy \
     --policy-arn 'arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly' \
     --role-name 'DeepThinkerNode'
   aws iam attach-role-policy \
     --policy-arn 'arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy' \
     --role-name 'DeepThinkerNode'
   ```

   </details>

   <details style="margin-bottom: 1em;">
     <summary>Example in Pulumi</summary>

   ```ts
   const nodes_assumeRole_policy = JSON.stringify({
       Version: "2012-10-17",
       Statement: [{
           Effect: "Allow",
           Action: "sts:AssumeRole",
           Principal: {
               Service: "ec2.amazonaws.com",
           },
       }],
   });

   const node_service_role = new aws.iam.Role("node-service-role", {
       assumeRolePolicy: nodes_assumeRole_policy,
       managedPolicyArns: [
           // alternatively, use RolePolicyAttachments
           "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
           "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
           "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
       ],
       name: "DeepThinkerNode",
       …
   });
   ```

   </details>

1. Create the desired node groups.

   <details>
     <summary>Example in CLI</summary>

   ```sh
   aws eks create-nodegroup \
     --cluster-name 'DeepThought' \
     --nodegroup-name 'alpha' \
     --scaling-config 'minSize=1,maxSize=3,desiredSize=1' \
     --node-role-arn 'arn:aws:iam::000011112222:role/DeepThinkerNode' \
     --subnets 'subnet-11112222333344445' 'subnet-66667777888899990'
   ```

   </details>

   <details>
     <summary>Example in Pulumi</summary>

   ```ts
   const nodeGroup_alpha = new aws.eks.NodeGroup("nodeGroup-alpha", {
       nodeGroupName: "nodeGroup-alpha",
       clusterName: cluster.name,
       nodeRoleArn: node_service_role.arn,
       scalingConfig: {
           minSize: 1,
           maxSize: 3,
           desiredSize: 1,
       },
       subnetIds: cluster.vpcConfig.subnetIds,
       …
   });
   ```

   </details>

### Schedule pods on Fargate

Additional requirements:

- \[suggestion] 1 (one) custom _Fargate Service Role_ with the `AmazonEKSFargatePodExecutionRolePolicy` policy attached
  or similar permissions.

  To create pods on Fargate, the components running on Fargate must make calls to the AWS APIs on one's behalf.<br/>
  This is so that it can take actions such as pull container images from ECR or route logs to other AWS services.

  For a cluster to be allowed to make those calls, it **requires** to have a Fargate profile assigned, and this profile
  must use a role with:

  - The `AmazonEKSFargatePodExecutionRolePolicy` policy attached to it, or
  - Comparable permissions.

- 1+ (one or more) Fargate profile(s).

Procedure:

1. Create a custom IAM role for the Fargate profile if needed (see [Requirements]).
1. Attach the required policies to the role used by the profile.

   <details>
     <summary>Example in CLI</summary>

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": "sts:AssumeRole",
               "Principal": {
                   "Service": "eks-fargate-pods.amazonaws.com"
               },
               "Condition": {
                    "ArnLike": {
                         "aws:SourceArn": "arn:aws:eks:region-code:111122223333:fargateprofile/my-cluster/*"
                    }
               }
           }
       ]
   }
   ```

   ```sh
   aws iam create-role \
     --role-name 'DeepThinkerFargate' \
     --assume-role-policy-document 'file://eks-cluster-role-trust-policy.json'
   aws iam attach-role-policy \
     --role-name 'DeepThinkerFargate' \
     --policy-arn 'arn:aws:iam::aws:policy/AmazonEKSClusterPolicy'
   ```

   </details>

   <details style="margin-bottom: 1em;">
     <summary>Example in Pulumi</summary>

   ```ts
   const fargate_assumeRole_policy = JSON.stringify({
       Version: "2012-10-17",
       Statement: [{
           Effect: "Allow",
           Action: "sts:AssumeRole",
           Principal: {
               Service:  "eks-fargate-pods.amazonaws.com",
           },
           Condition: {
               ArnLike: {
                   "aws:SourceArn": `arn:aws:eks:${region}:${account}:fargateprofile/${cluster.name}/*`
               }
           },
       }],
   });

   const fargate_service_role = new aws.iam.Role("fargate-service-role", {
       assumeRolePolicy: fargate_assumeRole_policy,
       managedPolicyArns: [
           // alternatively, use RolePolicyAttachments
           "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy",
       ],
       name: "DeepThinkerFargate",
       …
   });
   ```

   </details>

1. Create the desired Fargate profiles.

   <details>
     <summary>Example in CLI</summary>

   ```sh
   aws eks create-fargate-profile \
     --cluster-name 'DeepThought' \
     --fargate-profile-name 'alpha' \
     --pod-execution-role-arn 'arn:aws:iam::000011112222:role/DeepThinkerFargate' \
     --subnets 'subnet-11112222333344445' 'subnet-66667777888899990' \
     --selectors 'namespace=string'
   ```

   </details>

   <details>
     <summary>Example in Pulumi</summary>

   ```ts
   const fargateProfile_alpha = new aws.eks.FargateProfile("fargateProfile-alpha", {
       fargateProfileName: "fargateProfile-alpha",
       clusterName: cluster.name,
       podExecutionRoleArn: fargate_service_role.arn,
       selectors: [
           { namespace: "monitoring" },
           { namespace: "default" },
       ],
       subnetIds: cluster.vpcConfig.subnetIds,
       …
   });
   ```

   </details>

## Access management

The current default authentication method is through the `aws-auth` configmap in the `kube-system` namespace.

By default, the IAM principal creating the cluster is the only one able to make calls to the cluster's API server.<br/>
To let other IAM principals have access to the cluster, one needs to add them to it.

See the following to allow others:

- [Required permissions to view EKS resources].
- [Enabling IAM principal access to your cluster].
- [Allowing IAM roles or users access to Kubernetes objects on your Amazon EKS cluster].
- [How do I resolve the error "You must be logged in to the server (Unauthorized)" when I connect to the Amazon EKS API server?]
- [Identity and Access Management]
- [Using IAM Groups to manage Kubernetes cluster access]
- [Simplified Amazon EKS Access - NEW Cluster Access Management Controls]

When a cluster's authentication mode includes the APIs:

```sh
# Check cluster's authentication mode.
$ aws eks describe-cluster --name 'thisIsBananas' --query 'cluster.accessConfig.authenticationMode' --output 'text'
API_AND_CONFIG_MAP
```

One can use access entries to allow IAM users and roles to connect to it:

```sh
# Create access entries to use IAM for authentication.
aws eks create-access-entry --cluster-name 'DeepThought' \
  --principal-arn 'arn:aws:iam::000011112222:role/Admin'
aws eks create-access-entry … --principal-arn 'arn:aws:iam::000011112222:user/bob'
```

> In the case the configmap is also used, APIs take precedence over the configmap.

Mind that, to allow operations inside the cluster, every access entry requires to be assigned an EKS access policy:

```sh
# List available access policies.
aws eks list-access-policies

# Associate policies to access entries.
aws eks associate-access-policy --cluster-name 'DeepThought' \
  --principal-arn 'arn:aws:iam::000011112222:role/Admin' \
  --policy-arn 'arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy' \
  --access-scope '[ "type": "cluster" ]'
aws eks associate-access-policy --cluster-name 'DeepThought' \
  --principal-arn 'arn:aws:iam::000011112222:user/bob' \
  --policy-arn 'arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy' \
  --access-scope '[ "type": "namespace", "namespaces": [ "bob" ] ]'
```

## Secrets encryption through KMS

See [Enabling secret encryption on an existing cluster].

TL;DR:

1. Make sure the role used in the cluster has access to the used key with `kms:DescribeKey` and `kms:CreateGrant`
   permissions.
1. Configure the cluster:

   <details>
     <summary>Example in CLI</summary>

   ```sh
   aws eks associate-encryption-config \
     --cluster-name 'DeepThought' \
     --encryption-config '[{
       "provider": { "keyArn": "arn:aws:kms:eu-west-1:000011112222:key/33334444-5555-6666-7777-88889999aaaa" },
       "resources": [ "secrets" ]
     }]'
   ```

   </details>

   <details>
     <summary>Example in Pulumi</summary>

   ```ts
   const cluster = new aws.eks.Cluster("cluster", {
       encryptionConfig: {
           provider: { keyArn: `arn:aws:kms:${region}:${account}:key/${key_id}` },
           resources: [ "secrets" ],
       },
       …
   });
   ```

   </details>

## Storage

Refer [How do I use persistent storage in Amazon EKS?], [Fargate storage] and
[Running stateful workloads with Amazon EKS on AWS Fargate using Amazon EFS] for this.

## Troubleshooting

See [Amazon EKS troubleshooting].

### Identify common issues

Use the [AWSSupport-TroubleshootEKSWorkerNode](https://docs.aws.amazon.com/systems-manager-automation-runbooks/latest/userguide/automation-awssupport-troubleshooteksworkernode.html) runbook.

> For the automation to work, worker nodes **must** have permission to access Systems Manager and have Systems Manager
> running.<br/>
> Grant this permission by attaching the [`AmazonSSMManagedInstanceCore`](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-profile.html#instance-profile-policies-overview) policy to the node role.

Procedure:

1. Open the [runbook](https://console.aws.amazon.com/systems-manager/automation/execute/AWSSupport-TroubleshootEKSWorkerNode).
1. Check that the AWS Region in the Management Console is set to the same Region as your cluster.
1. In the Input parameters section, specify the name of the cluster and the EC2 instance ID.
1. \[optional] In the `AutomationAssumeRole` field, specify a role to allow Systems Manager to perform actions.<br/>
   If left empty, the permissions of your current IAM entity are used to perform the actions in the runbook.
1. Choose `Execute`.
1. Check the `Outputs` section.

### The worker nodes fail to join the cluster

Error message example:

> NodeCreationFailure: Instances failed to join the kubernetes cluster.

Debug: see [Identify common issues].

## Further readings

- [Amazon Web Services]
- [Kubernetes]
- [EKS Workshop]
- [Pulumi]
- [Terraform]
- AWS' [CLI]
- [How can I get my worker nodes to join my Amazon EKS cluster?]
- [Enabling IAM principal access to your cluster]
- [Allowing IAM roles or users access to Kubernetes objects on your Amazon EKS cluster]
- [How do I resolve the error "You must be logged in to the server (Unauthorized)" when I connect to the Amazon EKS API server?]
- [Identity and Access Management]
- [How do I use persistent storage in Amazon EKS?]
- [Running stateful workloads with Amazon EKS on AWS Fargate using Amazon EFS]

### Sources

- [Getting started with Amazon EKS - AWS Management Console and AWS CLI]
- [`aws eks create-cluster`][aws eks create-cluster]
- [`aws eks create-nodegroup`][aws eks create-nodegroup]
- [`aws eks create-fargate-profile`][aws eks create-fargate-profile]
- [Using service-linked roles for Amazon EKS]
- [Service-linked role permissions for Amazon EKS]
- [Amazon EKS cluster IAM role]
- [Amazon EKS VPC and subnet requirements and considerations]
- [Amazon EKS security group requirements and considerations]
- [Amazon EKS clusters]
- [Amazon EKS add-ons]
- [Enabling secret encryption on an existing cluster]
- [Choosing an Amazon EC2 instance type]
- [Private cluster requirements]
- [De-mystifying cluster networking for Amazon EKS worker nodes]
- [Simplified Amazon EKS Access - NEW Cluster Access Management Controls]

<!--
  References
  -->

<!-- In-article sections -->
[access management]: #access-management
[create worker nodes]: #create-worker-nodes
[identify common issues]: #identify-common-issues
[requirements]: #requirements
[secrets encryption through kms]: #secrets-encryption-through-kms

<!-- Knowledge base -->
[amazon web services]: README.md
[cli]: cli.md
[kubernetes]: ../../kubernetes/README.md
[pulumi]: ../../pulumi.md
[terraform]: ../../pulumi.md

<!-- Files -->
<!-- Upstream -->
[allowing iam roles or users access to kubernetes objects on your amazon eks cluster]: https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html
[amazon eks add-ons]: https://docs.aws.amazon.com/eks/latest/userguide/eks-add-ons.html
[amazon eks cluster iam role]: https://docs.aws.amazon.com/eks/latest/userguide/service_IAM_role.html
[amazon eks clusters]: https://docs.aws.amazon.com/eks/latest/userguide/clusters.html
[amazon eks security group requirements and considerations]: https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html
[amazon eks troubleshooting]: https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html
[amazon eks vpc and subnet requirements and considerations]: https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
[amazoneksclusterpolicy]: https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEKSClusterPolicy.html
[amazoneksservicepolicy]: https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEKSServicePolicy.html
[aws eks create-cluster]: https://docs.aws.amazon.com/cli/latest/reference/eks/create-cluster.html
[aws eks create-fargate-profile]: https://docs.aws.amazon.com/cli/latest/reference/eks/create-fargate-profile.html
[aws eks create-nodegroup]: https://docs.aws.amazon.com/cli/latest/reference/eks/create-nodegroup.html
[choosing an amazon ec2 instance type]: https://docs.aws.amazon.com/eks/latest/userguide/choosing-instance-type.html
[de-mystifying cluster networking for amazon eks worker nodes]: https://aws.amazon.com/blogs/containers/de-mystifying-cluster-networking-for-amazon-eks-worker-nodes/
[eks workshop]: https://www.eksworkshop.com/
[enabling iam principal access to your cluster]: https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html
[enabling secret encryption on an existing cluster]: https://docs.aws.amazon.com/eks/latest/userguide/enable-kms.html
[fargate storage]: https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html#fargate-storage
[fargate]: https://docs.aws.amazon.com/eks/latest/userguide/fargate.html
[getting started with amazon eks - aws management console and aws cli]: https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html
[how can i get my worker nodes to join my amazon eks cluster?]: https://repost.aws/knowledge-center/eks-worker-nodes-cluster
[how do i resolve the error "you must be logged in to the server (unauthorized)" when i connect to the amazon eks api server?]: https://repost.aws/knowledge-center/eks-api-server-unauthorized-error
[how do i use persistent storage in amazon eks?]: https://repost.aws/knowledge-center/eks-persistent-storage
[identity and access management]: https://aws.github.io/aws-eks-best-practices/security/docs/iam/
[managed node groups]: https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html
[private cluster requirements]: https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html
[required permissions to view eks resources]: https://docs.aws.amazon.com/eks/latest/userguide/view-kubernetes-resources.html#view-kubernetes-resources-permissions
[running stateful workloads with amazon eks on aws fargate using amazon efs]: https://aws.amazon.com/blogs/containers/running-stateful-workloads-with-amazon-eks-on-aws-fargate-using-amazon-efs/
[self-managed nodes]: https://docs.aws.amazon.com/eks/latest/userguide/worker.html
[service-linked role permissions for amazon eks]: https://docs.aws.amazon.com/eks/latest/userguide/using-service-linked-roles-eks.html#service-linked-role-permissions-eks
[simplified amazon eks access - new cluster access management controls]: https://www.youtube.com/watch?v=ae25cbV5Lxo
[using iam groups to manage kubernetes cluster access]: https://archive.eksworkshop.com/beginner/091_iam-groups/
[using service-linked roles for amazon eks]: https://docs.aws.amazon.com/eks/latest/userguide/using-service-linked-roles.html

<!-- Others -->
