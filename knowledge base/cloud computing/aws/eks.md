# Elastic Kubernetes Service

1. [TL;DR](#tldr)
1. [Requirements](#requirements)
1. [Creation procedure](#creation-procedure)
1. [Create worker nodes](#create-worker-nodes)
   1. [Create managed node groups](#create-managed-node-groups)
   1. [Schedule pods on Fargate](#schedule-pods-on-fargate)
1. [Secrets encryption through KMS](#secrets-encryption-through-kms)
1. [Troubleshooting](#troubleshooting)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

When one creates a [_cluster_][amazon eks clusters], one really only creates the cluster's control plane and the dedicated nodes underneath it.<br/>
Worker nodes can consist in any combination of [self-managed nodes], [managed node groups] and [Fargate], and depend on the control plane.

EKS automatically installs [self-managed add-ons][amazon eks add-ons] like the AWS VPC CNI plugin, `kube-proxy` and CoreDNS.<br/>
Disable them in the cluster's definition.

Upon cluster creation, EKS [automatically creates a security group][amazon eks security group requirements and considerations] and applies it to both the control plane and nodes.<br/>
Such security group cannot be avoided nor customized in the cluster's definition (e.g. using IaC tools like [Pulumi] or [Terraform]):

> ```txt
> error: aws:eks/cluster:Cluster resource 'cluster' has a problem: Value for unconfigurable attribute. Can't configure a value for "vpc_config.0.cluster_security_group_id": its value will be decided automatically based on the result of applying this configuration.
> ```

For some reason, giving resources a tag like `aks:eks:cluster-name=value` succeeds, but has no effect (it is not really applied).

By default, the IAM principal creating the cluster is the only one able to make calls to the cluster's API server.<br/>
To let other IAM principals have access to the cluster, one needs to add them to it. See [Enabling IAM principal access to your cluster](https://docs.aws.amazon.com/eks/latest/userguide/add-user-role.html) and [Required permissions](https://docs.aws.amazon.com/eks/latest/userguide/view-kubernetes-resources.html#view-kubernetes-resources-permissions) to do so.

<details>
  <summary>Usage</summary>

  ```sh
  # Create clusters.
  aws eks create-cluster \
    --name 'DeepThought' \
    --role-arn 'arn:aws:iam::000011112222:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS' \
    --resources-vpc-config 'subnetIds=subnet-11112222333344445,subnet-66667777888899990'

  # Connect to clusters.
  aws eks update-kubeconfig --name 'name' && kubectl cluster-info

  # Change encryption configuration.
  aws eks associate-encryption-config \
    --cluster-name 'DeepThought' \
    --encryption-config '[{
      "provider": { "keyArn": "arn:aws:kms:eu-west-1:000011112222:key/33334444-5555-6666-7777-88889999aaaa" },
      "resources": [ "secrets" ]
    }]'


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

- [suggestion] 1 (one) custom _Cluster Service Role_ with the `AmazonEKSClusterPolicy` policy attached or similar custom permissions.

  Kubernetes clusters managed by EKS make calls to other AWS services on the user's behalf to manage the resources that the cluster uses.<br/>
  For a cluster to be allowed to make those calls, it **requires** to have the aforementioned permissions.

  To create clusters which would **not** require access to any other AWS resource, one can assign the cluster the `AWSServiceRoleForAmazonEKS` service-linked role directly <sup>[1][service-linked role permissions for amazon eks],[2][amazon eks cluster iam role]</sup>.

  > Amazon EKS uses the service-linked role named `AWSServiceRoleForAmazonEKS` - The role allows Amazon EKS to manage clusters in your account. The attached policies allow the role to manage the following resources: network interfaces, security groups, logs, and VPCs.

  > Prior to October 3, 2023, [AmazonEKSClusterPolicy] was required on the IAM role for each cluster.
  >
  > Prior to April 16, 2020, [AmazonEKSServicePolicy] was also required and the suggested name was `eksServiceRole`. With the `AWSServiceRoleForAmazonEKS` service-linked role, that policy is no longer required for clusters created on or after April 16, 2020.

  <div class="tip" style="
    background-color: rgba(0,255,0,0.0625);
    border: solid lightGreen;  /* #90EE90 */
    margin: 1em 0;
    padding: 1em 1em 0;
  ">
  <header style="font-weight: bold; margin-bottom: 0.5em">Pro tip</header>

  Should one want to use more advanced features like [encryption with managed keys][secrets encryption through kms], the role will need access to the referenced resources.<br/>
  In this case it would probably be better to create a custom role instead of assigning permissions to the built-in one.

  </div>

- [suggestion] 1+ (one or more) custom service role(s) for the pod executors, with the required policies attached or similar permissions.

  The reasons and required permissions vary depending on the type of executor.<br/>
  It would probably be better to create a custom role instead of assigning permissions to the built-in one.

  See the corresponding section under [Create worker nodes].

- Private clusters have [more special requirements][private cluster requirements] of their own.

## Creation procedure

The Internet is full of guides and abstractions which do not work, are confusing, or rely on other code.<br/>
Some create Cloudformation stacks in the process.

1. Create a VPC, if one does not have them already, with public and private subnets that meet [EKS' requirements][amazon eks vpc and subnet requirements and considerations].

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
   ```

   </details>

   <details>
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
     name: "DeepThinker",
     …
   });
   ```

   </details>
   <br/>

1. Create the cluster.

   <details>
     <summary>Example in CLI</summary>

   ```sh
   aws eks create-cluster \
     --name 'DeepThought' \
     --role-arn 'arn:aws:iam::000011112222:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS' \
     --resources-vpc-config 'subnetIds=subnet-11112222333344445,subnet-66667777888899990'
   ```

   </details>

   <details>
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
   <br/>

1. Connect to the cluster.

   ```sh
   $ aws eks update-kubeconfig --name 'DeepThought'
   Added new context arn:aws:eks:eu-east-1:000011112222:cluster/DeepThought to /home/itsAme/.kube/config

   $ kubectl cluster-info
   Kubernetes control plane is running at https://FB32A9C4A3D6BBC82695B1936BF4AAA3.gr7.eu-east-1.eks.amazonaws.com
   CoreDNS is running at https://FB32A9C4A3D6BBC82695B1936BF4AAA3.gr7.eu-east-1.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
   ```

1. [Create some worker nodes][create worker nodes].
1. TODO

## Create worker nodes

See [step 3](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html#eks-launch-workers) of the [getting started guide][getting started with amazon eks - aws management console and aws cli].

### Create managed node groups

See [Choosing an Amazon EC2 instance type] and [Managed node groups] for more information.

Additional requirements:

- [suggestion] 1 (one) custom _Node Service Role_ with the `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly` and `AmazonEKS_CNI_Policy` policies attached or similar permissions.

  The EKS nodes' `kubelet` makes calls to the AWS APIs on one's behalf.<br/>
  Nodes receive permissions for these API calls through an IAM instance profile and associated policies.

  For a node to be allowed to make those calls, it **requires** to have the aforementioned permissions.

- When deploying a managed node group in **private** subnets, one must ensure that it can access Amazon ECR for pulling container images.<br/>
  Do this by connecting a NAT gateway to the route table of the subnet, or by adding the following AWS PrivateLink VPC endpoints:

  - Amazon ECR API endpoint interface: `com.amazonaws.{region}.ecr.api`.
  - Amazon ECR Docker registry API endpoint interface: `com.amazonaws.{region}.ecr.dkr`.
  - Amazon S3 gateway endpoint: `com.amazonaws.{region}.s3`.

- If the nodes are to be created in private subnets, the cluster [**must** provide its private API server endpoint](https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html).<br/>
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

   <details>
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
   <br/>

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

- [suggestion] 1 (one) custom _Fargate Service Role_ with the `AmazonEKSFargatePodExecutionRolePolicy` policy attached or similar permissions.

  To create pods on Fargate, the components running on Fargate must make calls to the AWS APIs on one's behalf.<br/>
  This is so that it can take actions such as pull container images from ECR or route logs to other AWS services.

  For a cluster to be allowed to make those calls, it **requires** to have a Fargate profile assigned, and this profile must use a role with:

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

   <details>
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
   <br/>

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

## Secrets encryption through KMS

See [Enabling secret encryption on an existing cluster].

TL;DR:

1. Make sure the role used in the cluster has access to the used key with `kms:DescribeKey` and `kms:CreateGrant` permissions.
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

## Troubleshooting

See [Amazon EKS troubleshooting].

## Further readings

- [Kubernetes]
- [EKS Workshop]
- [Pulumi]
- [Terraform]

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

<!--
  References
  -->

<!-- In-article sections -->
[create worker nodes]: #create-worker-nodes
[requirements]: #requirements
[secrets encryption through kms]: #secrets-encryption-through-kms

<!-- Knowledge base -->
[kubernetes]: ../../kubernetes/README.md
[pulumi]: ../../pulumi.md
[terraform]: ../../pulumi.md

<!-- Files -->
<!-- Upstream -->
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
[eks workshop]: https://www.eksworkshop.com/
[enabling secret encryption on an existing cluster]: https://docs.aws.amazon.com/eks/latest/userguide/enable-kms.html
[fargate]: https://docs.aws.amazon.com/eks/latest/userguide/fargate.html
[getting started with amazon eks - aws management console and aws cli]: https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html
[managed node groups]: https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html
[private cluster requirements]: https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html
[self-managed nodes]: https://docs.aws.amazon.com/eks/latest/userguide/worker.html
[service-linked role permissions for amazon eks]: https://docs.aws.amazon.com/eks/latest/userguide/using-service-linked-roles-eks.html#service-linked-role-permissions-eks
[using service-linked roles for amazon eks]: https://docs.aws.amazon.com/eks/latest/userguide/using-service-linked-roles.html

<!-- Others -->