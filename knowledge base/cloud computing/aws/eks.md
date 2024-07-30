# Elastic Kubernetes Service

1. [TL;DR](#tldr)
1. [Requirements](#requirements)
1. [Cluster creation procedure](#cluster-creation-procedure)
1. [Access management](#access-management)
   1. [OIDC providers](#oidc-providers)
1. [Create worker nodes](#create-worker-nodes)
   1. [Create managed node groups](#create-managed-node-groups)
   1. [Schedule pods on Fargate](#schedule-pods-on-fargate)
1. [Secrets encryption through KMS](#secrets-encryption-through-kms)
1. [Storage](#storage)
   1. [Use EBS as volumes](#use-ebs-as-volumes)
1. [Autoscaling](#autoscaling)
1. [Add-ons](#add-ons)
   1. [Metrics server](#metrics-server)
   1. [Pod identity](#pod-identity)
   1. [Cluster autoscaler](#cluster-autoscaler)
   1. [AWS Load Balancer Controller](#aws-load-balancer-controller)
   1. [EBS CSI driver](#ebs-csi-driver)
      1. [EBS CSI driver as aws-managed add-on](#ebs-csi-driver-as-aws-managed-add-on)
      1. [EBS CSI driver as self-managed add-on](#ebs-csi-driver-as-self-managed-add-on)
1. [Troubleshooting](#troubleshooting)
    1. [Identify common issues](#identify-common-issues)
    1. [The worker nodes fail to join the cluster](#the-worker-nodes-fail-to-join-the-cluster)
    1. [AWS ELB controller fails to get the region from the host's metadata](#aws-elb-controller-fails-to-get-the-region-from-the-hosts-metadata)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

When one creates a [_cluster_][amazon eks clusters], one really only creates the cluster's _[control plane]_ with the
AWS managed, dedicated nodes that keep it running.

_Worker nodes_ depend upon the control plane, and **must** be created **after** the control plane.<br/>
Worker nodes can consist of any combination of [self-managed nodes], [managed node groups] and [Fargate], but only
support specific instance types.

EKS automatically installs some [self-managed add-ons][amazon eks add-ons] like the AWS VPC CNI plugin, `kube-proxy` and
CoreDNS to allow the cluster to work correctly in AWS.<br/>
Add-ons _can_ be disabled **after** creation or in the clusters' IaC.

Upon cluster creation, EKS
[automatically creates a security group][amazon eks security group requirements and considerations] and applies it to
both the control plane and nodes.<br/>
It appears the creation of this security group **cannot** be avoided, nor the security group can be customized in the
cluster's definition (e.g. using IaC tools like [Pulumi] or [Terraform]):

> error: aws:eks/cluster:Cluster resource 'cluster' has a problem: Value for unconfigurable attribute. Can't configure a
> value for "vpc_config.0.cluster_security_group_id": its value will be decided automatically based on the result of
> applying this configuration.

For some reason, giving resources a tag like `aks:eks:cluster-name=value` succeeds, but has no effect (the tag is just
**not** applied).

By default, the IAM principal creating the cluster is the **only** one allowed to make calls to the cluster's API
server.<br/>
Other IAM principals _can_ have access to the cluster's API once [they are added to it][access management].

Pods can assume IAM roles through Kubernetes service accounts, provided the service accounts have been associated the
roles by leveraging:

- [OIDC providers], and/or
- [Pod Identity].

<details>
  <summary>Usage</summary>

```sh
# Create clusters.
aws eks create-cluster --name 'DeepThought' \
  --role-arn 'arn:aws:iam::000011112222:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS' \
  --resources-vpc-config 'subnetIds=subnet-11112222333344445,subnet-66667777888899990'
aws eks create-cluster … --access-config 'authenticationMode=API'

# Check clusters' authentication mode.
aws eks describe-cluster --name 'DeepThought' --query 'cluster.accessConfig.authenticationMode' --output 'text'

# Change encryption configuration.
aws eks associate-encryption-config --cluster-name 'DeepThought' \
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
aws eks --region 'eu-west-1' update-kubeconfig --name 'DeepThought' --profile 'dev-user' && kubectl cluster-info


# Create EC2 node groups.
aws eks create-nodegroup --cluster-name 'DeepThought' \
  --nodegroup-name 'alpha' \
  --scaling-config 'minSize=1,maxSize=3,desiredSize=1' \
  --node-role-arn 'arn:aws:iam::000011112222:role/DeepThoughtNodeGroupsServiceRole' \
  --subnets 'subnet-11112222333344445' 'subnet-66667777888899990'

# Create Fargate profiles.
aws eks create-fargate-profile --cluster-name 'DeepThought' \
  --fargate-profile-name 'alpha' \
  --pod-execution-role-arn 'arn:aws:iam::000011112222:role/DeepThoughtFargateServiceRole' \
  --subnets 'subnet-11112222333344445' 'subnet-66667777888899990' \
  --selectors 'namespace=string'


# Get addon names.
aws eks describe-addon-versions --query 'addons[].addonName'

# Get addon versions.
aws eks describe-addon-versions --addon-name 'eks-pod-identity-agent' --query 'addons[].addonVersions[]'

# Get addon configuration options.
aws eks describe-addon-configuration --addon-name 'aws-ebs-csi-driver' --addon-version 'v1.32.0-eksbuild.1'
```

</details>

<!-- Uncomment if needed
<details>
  <summary>Real world use cases</summary>
</details>
-->

## Requirements

- \[suggested] 1 (one) custom _Cluster Service Role_.<br/>
  One **must** attach this role the `AmazonEKSClusterPolicy` IAM policy, give it similar custom permissions.

  <details style="margin-bottom: 1em">
    <summary>But why?!</summary>

  Kubernetes clusters managed by EKS make calls to other AWS services on the users' behalf to manage the resources that
  the cluster uses.<br/>
  For any cluster to be allowed to make such calls, its role **requires** to have the aforementioned permissions.

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

  </details>

  Pro tip:<br/>
  Should one want to use more advanced features like [encryption with managed keys][secrets encryption through kms], the
  role **will** need access to the referenced resources.<br/>
  In such a case, it's generally better to create a custom role instead of assigning permissions to the built-in one.

- \[suggested] 1+ (one or more) custom service role(s) for the worker nodes.<br/>
  Best practice would dictate to create **one role per worker node type**, and to attach each of them only the policies
  they require (or giving them similar custom permissions).

  The reasons and required permissions vary depending on the type of worker node.<br/>
  It's generally better to create a custom role instead of assigning permissions to the built-in one.<br/>
  See the corresponding section under [Create worker nodes].

- 1+ (one or more) worker node type.<br/>
  See the [Create worker nodes] section.

- \[if using APIs for authentication] 1+ (one or more) access entry (/entries) with an EKS access policy assigned.

- _Private_ clusters have [more special requirements][private cluster requirements] of their own.

## Cluster creation procedure

The Internet is full of guides and abstractions which do not work, are confusing, or rely on other code.<br/>
Some even create Cloudformation stacks in the process. _WHY?! (╯°Д°)╯︵ ┻━┻_.

Follow the [Getting started guide][getting started with amazon eks - aws management console and aws cli] to avoid
issues.

This is what worked for me:

1. Create a VPC, if one does not have them already, with public and private subnets that meet
   [EKS' requirements][amazon eks vpc and subnet requirements and considerations].

   [Cloudformation](https://s3.us-west-2.amazonaws.com/amazon-eks/cloudformation/2020-10-29/amazon-eks-vpc-private-subnets.yaml)

1. Create a custom IAM (service) role for the cluster if needed (see [Requirements]).
1. Attach the required policies to the cluster's service role.

   <details>
     <summary>Assume role policy definition</summary>

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

   </details>

   <details>
     <summary>CLI</summary>

   ```sh
   aws iam create-role \
     --role-name 'DeepThoughtClusterServiceRole' \
     --assume-role-policy-document 'file://eks-cluster-role-trust-policy.json'
   aws iam attach-role-policy \
     --role-name 'DeepThoughtClusterServiceRole' \
     --policy-arn 'arn:aws:iam::aws:policy/AmazonEKSClusterPolicy'
   ```

   </details>

   <details style="margin-bottom: 1em">
     <summary>Pulumi</summary>

   ```ts
   const cluster_service_role = new aws.iam.Role(
       "cluster-service-role",
       {
           assumeRolePolicy: cluster_assumeRole_policy,
           managedPolicyArns: [
               "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
           ],
           name: "DeepThoughtClusterServiceRole",
       },
   );
   ```

   </details>

1. Create the cluster('s control plane).<br/>
   Make sure you give it the correct cluster service role.

   <details>
     <summary>CLI</summary>

   ```sh
   aws eks create-cluster --name 'DeepThought' \
     --role-arn 'arn:aws:iam::000011112222:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS' \
     --resources-vpc-config 'subnetIds=subnet-11112222333344445,subnet-66667777888899990'
   ```

   </details>

   <details style="margin-bottom: 1em">
     <summary>Pulumi</summary>

   ```ts
   const cluster = new aws.eks.Cluster(
       "cluster",
       {
           name: "DeepThought",
           roleArn: cluster_service_role.arn,
           vpcConfig: {
               subnetIds: [
                   "subnet-11112222333344445",
                   "subnet-66667777888899990",
               ],
           },
       },
   );
   ```

   </details>

1. [Give access to users][access management].
1. Connect to the cluster.

   ```sh
   $ aws eks update-kubeconfig --name 'DeepThought'
   Added new context arn:aws:eks:eu-east-1:000011112222:cluster/DeepThought to /home/itsAme/.kube/config

   $ kubectl cluster-info
   Kubernetes control plane is running at https://0123456789ABCDEF0123456789ABCDEF.gr7.eu-east-1.eks.amazonaws.com
   CoreDNS is running at https://0123456789ABCDEF0123456789ABCDEF.gr7.eu-east-1.eks.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
   ```

1. [Create some worker nodes][create worker nodes].
1. Profit!

## Access management

The current default authentication method for EKS clusters created using AWS' APIs is through the `aws-auth` configMap
stored in the `kube-system` namespace.

By default, **only** the IAM principal creating the cluster is added to that configMap.<br/>
As such, **only that principal** is allowed to make calls to that cluster's API server.

To allow other IAM principals to call the cluster's API, the cluster's creator needs to add them to the `aws-auth`
configMap.<br/>
Refer the following to allow others this way:

- [Required permissions to view EKS resources].
- [Enabling IAM principal access to your cluster].
- [Allowing IAM roles or users access to Kubernetes objects on your Amazon EKS cluster].
- [How do I resolve the error "You must be logged in to the server (Unauthorized)" when I connect to the Amazon EKS API server?]
- [Identity and Access Management]
- [Using IAM Groups to manage Kubernetes cluster access]
- [Simplified Amazon EKS Access - NEW Cluster Access Management Controls]

When a cluster's authentication mode includes the APIs, one can allow IAM users and roles to connect to and operate on
it by creating _access entries_:

```sh
$ aws eks describe-cluster --name 'DeepThought' --query 'cluster.accessConfig.authenticationMode' --output 'text'
API_AND_CONFIG_MAP
$ aws eks describe-cluster --name 'Marvin' --query 'cluster.accessConfig.authenticationMode' --output 'text'
API

$ aws eks create-access-entry --cluster-name 'DeepThought' --principal-arn 'arn:aws:iam::000011112222:role/Admin'
$ aws eks create-access-entry … --principal-arn 'arn:aws:iam::000011112222:user/bob'
```

To allow operations **inside** the cluster, every access entry **requires** to be also assigned an EKS access policy:

```sh
aws eks associate-access-policy --cluster-name 'DeepThought' \
  --principal-arn 'arn:aws:iam::000011112222:role/Admin' \
  --policy-arn 'arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy' \
  --access-scope '[ "type": "cluster" ]'
aws eks associate-access-policy --cluster-name 'DeepThought' \
  --principal-arn 'arn:aws:iam::000011112222:user/bob' \
  --policy-arn 'arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy' \
  --access-scope '[ "type": "namespace", "namespaces": [ "bob" ] ]'
```

Should both configmap and APIs being used, the APIs **take precedence** over the configmap.

### OIDC providers

Clusters are associated an OpenID Connect (OIDC) issuer URL upon creation.<br/>
IAM OIDC providers can be created for one's cluster's OIDC issuer URL to use IAM roles for service accounts.<br/>
Providers can be used as alternative to [Pod Identity] associations.

<details>
  <summary>CLI</summary>

```sh
# 1. Get the OIDC issuer ID for existing EKS clusters
OIDC_ISSUER="$(aws eks describe-cluster --name 'DeepThought' --query 'cluster.identity.oidc.issuer' --output 'text')"
OIDC_ID="$(echo "$OIDC_ISSUER" | awk -F '/id/' '{print $2}')"
# 2. Check they are present in the list of providers for the account
aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList' --output 'text' | grep "$OIDC_ID"
# 3. If the providers do not exist, create them
aws create create-open-id-connect-provider --url "$OIDC_ISSUER" --client-id-list 'sts.amazonaws.com'
```

</details>

<details style="margin-bottom: 1em">
  <summary>Pulumi</summary>

```ts
const oidcProvider = new aws.iam.OpenIdConnectProvider(
    "cluster",
    {
        clientIdLists: [ "sts.amazonaws.com" ],
        thumbprintLists: [ "0123456789abcdef0123456789abcdef01234567" ],  // FIXME: use reference
        url: cluster.identities[0].oidcs[0].issuer,
    },
);
```

</details>

To use the OIDC provider, roles need to be configured with an assume policy like the following:

```json
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": {
            "Federated": "arn:aws:iam::012345678901:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/0123456789ABCDEF0123456789ABCDEF"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
            "StringEquals": {
                "oidc.eks.eu-west-1.amazonaws.com/id/0123456789ABCDEF0123456789ABCDEF:aud": "sts.amazonaws.com",
                "oidc.eks.eu-west-1.amazonaws.com/id/0123456789ABCDEF0123456789ABCDEF:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            }
        }
    }]
}
```

## Create worker nodes

Refer [step 3](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html#eks-launch-workers) of the
[getting started guide][getting started with amazon eks - aws management console and aws cli].

### Create managed node groups

Refer [Choosing an Amazon EC2 instance type] and [Managed node groups] for more information and what instance types are
supported.

Additional requirements:

- \[suggested] 1 (one) custom _Node Group Service Role_.<br/>
  Attach to it the `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly` and `AmazonEKS_CNI_Policy`
  policies, or give it similar custom permissions.

  <details style="margin-bottom: 1em">
    <summary>But why?!</summary>

  The EKS nodes' `kubelet`s make calls to the AWS APIs on one's behalf.<br/>
  Nodes receive permissions for these API calls through an IAM instance profile and associated policies.

  For any node to be allowed to make those calls, it **requires** to have the aforementioned permissions.

  </details>

- When deploying managed node groups in **private** subnets, they **will** need access to Amazon ECRs for pulling
  container images.<br/>
  Do this by connecting a NAT gateway to the route table of the private subnets, or by creating the following AWS
  PrivateLink VPC endpoints:

  - Amazon ECR API endpoint interface: `com.amazonaws.{region}.ecr.api`.
  - Amazon ECR Docker registry API endpoint interface: `com.amazonaws.{region}.ecr.dkr`.
  - Amazon S3 gateway endpoint: `com.amazonaws.{region}.s3`.

- When deploying managed node groups in **private** subnets, the cluster
  [**must** provide its private API server endpoint][private cluster requirements].<br/>
  Set the cluster's `vpc_config.0.endpoint_private_access` attribute to `true`.

Procedure:

1. Create a custom IAM (service) role for the node groups if needed (see [Requirements] and the additional requirements
   above).
1. Attach the required policies to the node groups' service role.

   <details>
     <summary>Assume role policy definition</summary>

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

   </details>

   <details>
     <summary>CLI</summary>

   ```sh
   aws iam create-role \
     --role-name 'DeepThoughtNodeGroupsServiceRole' \
     --assume-role-policy-document 'file://eks-node-group-role-trust-policy.json'
   aws iam attach-role-policy \
     --policy-arn 'arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy' \
     --role-name 'DeepThoughtNodeGroupsServiceRole'
   aws iam attach-role-policy \
     --policy-arn 'arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly' \
     --role-name 'DeepThoughtNodeGroupsServiceRole'
   aws iam attach-role-policy \
     --policy-arn 'arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy' \
     --role-name 'DeepThoughtNodeGroupsServiceRole'
   ```

   </details>

   <details style="margin-bottom: 1em">
     <summary>Pulumi</summary>

   ```ts
   const nodeGroups_service_role = new aws.iam.Role(
       "nodeGroups-service-role",
       {
           assumeRolePolicy: nodeGroups_assumeRole_policy,
           managedPolicyArns: [
               "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
               "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
               "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
           ],
           name: "DeepThoughtNodeGroupsServiceRole",
       },
   );
   ```

   </details>

1. Create the desired node groups.

   <details>
     <summary>CLI</summary>

   ```sh
   aws eks create-nodegroup --cluster-name 'DeepThought' \
     --nodegroup-name 'alpha' \
     --scaling-config 'minSize=1,maxSize=3,desiredSize=1' \
     --node-role-arn 'arn:aws:iam::000011112222:role/DeepThoughtNodeGroupsServiceRole' \
     --subnets 'subnet-11112222333344445' 'subnet-66667777888899990'
   ```

   </details>

   <details>
     <summary>Pulumi</summary>

   ```ts
   const nodeGroup_alpha = new aws.eks.NodeGroup(
       "nodeGroup-alpha",
       {
           nodeGroupName: "nodeGroup-alpha",
           clusterName: cluster.name,
           nodeRoleArn: nodeGroups_service_role.arn,
           scalingConfig: {
               minSize: 1,
               maxSize: 3,
               desiredSize: 1,
           },
           subnetIds: cluster.vpcConfig.subnetIds,
       },
   );
   ```

   </details>

### Schedule pods on Fargate

Additional requirements:

- \[suggestion] 1 (one) custom _Fargate Service Role_.<br/>
  Attach to it the `AmazonEKSFargatePodExecutionRolePolicy` policy, or give it similar custom permissions.

  <details style="margin-bottom: 1em">
    <summary>But why?!</summary>

  To create pods on Fargate, the components running on Fargate must make calls to the AWS APIs on one's behalf.<br/>
  This is so that it can take actions such as pull container images from ECR or route logs to other AWS services.

  For a cluster to be allowed to make those calls, it **requires** to have a Fargate profile assigned, and this profile
  must use a role with the aforementioned permissions.

  </details>

- 1+ (one or more) Fargate profile(s).

Procedure:

1. Create a custom IAM (service) role for the Fargate profile if needed (see [Requirements] and the additional
   requirements above).
1. Attach the required policies to the Fargate service profile.

   <details>
     <summary>Assume role policy definition</summary>

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
                         "aws:SourceArn": "arn:aws:eks:region-code:111122223333:fargateprofile/DeepThought/*"
                    }
               }
           }
       ]
   }
   ```

   </details>

   <details>
     <summary>CLI</summary>

   ```sh
   aws iam create-role \
     --role-name 'DeepThoughtFargateServiceRole' \
     --assume-role-policy-document 'file://eks-fargate-role-trust-policy.json'
   aws iam attach-role-policy \
     --role-name 'DeepThoughtFargateServiceRole' \
     --policy-arn 'arn:aws:iam::aws:policy/AmazonEKSClusterPolicy'
   ```

   </details>

   <details style="margin-bottom: 1em">
     <summary>Pulumi</summary>

   ```ts
   const fargate_service_role = new aws.iam.Role(
       "fargate-service-role",
       {
           assumeRolePolicy: fargate_assumeRole_policy,
           managedPolicyArns: [
               "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy",
           ],
           name: "DeepThoughtFargateServiceRole",
       },
   );
   ```

   </details>

1. Create the desired Fargate profiles.

   <details>
     <summary>CLI</summary>

   ```sh
   aws eks create-fargate-profile --cluster-name 'DeepThought' \
     --fargate-profile-name 'alpha' \
     --pod-execution-role-arn 'arn:aws:iam::000011112222:role/DeepThoughtFargateServiceRole' \
     --subnets 'subnet-11112222333344445' 'subnet-66667777888899990' \
     --selectors 'namespace=monitoring' 'namespace=default'
   ```

   </details>

   <details>
     <summary>Pulumi</summary>

   ```ts
   const fargateProfile_alpha = new aws.eks.FargateProfile(
       "fargateProfile-alpha",
       {
           fargateProfileName: "fargateProfile-alpha",
           clusterName: cluster.name,
           podExecutionRoleArn: fargate_service_role.arn,
           selectors: [
               { namespace: "monitoring" },
               { namespace: "default" },
           ],
           subnetIds: cluster.vpcConfig.subnetIds,
       },
   );
   ```

   </details>

## Secrets encryption through KMS

Refer [Enabling secret encryption on an existing cluster].

Procedure:

1. Make sure the role used in the cluster has access to the used key with `kms:DescribeKey` and `kms:CreateGrant`
   permissions.
1. Configure the cluster to use the aforementioned key.

   <details>
     <summary>CLI</summary>

   ```sh
   aws eks associate-encryption-config --cluster-name 'DeepThought' \
     --encryption-config '[{
       "provider": { "keyArn": "arn:aws:kms:eu-west-1:000011112222:key/33334444-5555-6666-7777-88889999aaaa" },
       "resources": [ "secrets" ]
     }]'
   ```

   </details>

   <details>
     <summary>Pulumi</summary>

   ```ts
   new aws.eks.Cluster(
       "cluster",
       {
           encryptionConfig: {
               provider: { keyArn: `arn:aws:kms:${region}:${account}:key/${key_id}` },
               resources: [ "secrets" ],
           },
       },
   );
   ```

   </details>

## Storage

Refer [How do I use persistent storage in Amazon EKS?], [Fargate storage], and
[Running stateful workloads with Amazon EKS on AWS Fargate using Amazon EFS] for this.

Leverage Container Storage Interface (CSI) drivers.

### Use EBS as volumes

Refer [Use Amazon EBS storage] and [Amazon Elastic Block Store (EBS) CSI driver].

Kubernetes clusters can use [EBS] volumes as storage for generic ephemeral volumes and persistent volumes through the
EBS CSI driver.

Considerations:

- The EBS CSI driver needs to make calls to AWS' APIs on one's behalf.<br/>
  The driver's IAM role's permissions need to be [set accordingly][ebs csi driver as aws-managed add-on].
- The EBS CSI DaemonSet is **required** to mount EBS volumes.<br/>
  Fargate _can_ run the EBS _controller_ Pods, but it **cannot** run DaemonSets (including the CSI DaemonSet).<br/>
  This means that Fargate **won't be able** to mount EBS volumes, and that only EC2 nodes running the DaemonSet will be
  able to do that.
- The EBS CSI driver is **not** installed on clusters by default.<br/>
  Add it as an addon.
- The _managed_ and _self-managed_ add-ons **cannot** be installed at the same time.
- EKS does **not** automatically update the CSI Driver add-on when new versions are released, **nor** it does after
  clusters are updated to new Kubernetes minor versions.

Test the driver's installation:

```sh
# Refer https://docs.aws.amazon.com/eks/latest/userguide/ebs-sample-app.html
git clone 'https://github.com/kubernetes-sigs/aws-ebs-csi-driver.git'
cd 'aws-ebs-csi-driver/examples/kubernetes/dynamic-provisioning'
echo -e "parameters:\n  type: gp3" >> 'manifests/storageclass.yaml'
kubectl apply -f 'manifests/'
kubectl describe storageClass 'ebs-sc'
kubectl get pvc
kubectl get pv
kubectl exec -it 'app' -- cat '/data/out.txt'
kubectl delete -f 'manifests/'
```

'gp2' seem to still be the default EBS type at the time of writing.<br/>
Though it seems to be possible to add storage custom storage classes to the values file for the EBS CSI driver's helm
chart, this is not configurable from the AWS-managed add-on.

<details style="margin-bottom: 1em">
  <summary>Generic procedure to create the 'gp3' type and set that as the default</summary>

```sh
kubectl annotate sc 'gp2' 'storageclass.kubernetes.io/is-default-class'='false'
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
  name: gp3
parameters:
  type: gp3
provisioner: kubernetes.io/aws-ebs
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF
```

</details>

## Autoscaling

Clusters can automatically scale:

- _Horizontally_ (as in **number** of nodes) through the use of [Cluster Autoscaler].
- _Vertically_ (as in **size** of nodes) through the use of [Karpenter].

The pods running the autoscaling components **will need** the necessary permissions to operate on the cluster's
resources.<br/>
This means giving them pods access keys, or enabling [Pod Identity].

## Add-ons

EKS automatically installs some [self-managed add-ons][amazon eks add-ons] like the AWS VPC CNI plugin, `kube-proxy` and
CoreDNS to allow the cluster to work correctly in AWS.<br/>
Add-ons _can_ be disabled **after** creation or in the clusters' IaC.

### Metrics server

Refer [View resource usage with the KubernetesMetrics Server].

Required by the Horizontal Pod Autoscaler and Dashboard components.

Make sure to use a container port different from 10250 if using Fargate, as that port is reserved on it:

```sh
helm upgrade -i --repo 'https://kubernetes-sigs.github.io/metrics-server' \
  'metrics-server' 'metrics-server' \
  --namespace 'kube-system' \
  --set 'containerPort'='10251'
```

### Pod identity

Refer [Learn how EKS Pod Identity grants pods access to AWS services].

Provides pods the ability to manage AWS credentials in a similar way to how EC2 instance profiles provide credentials to
instances.<br/>
It can be used as alternative to [OIDC providers].

Limitations:

- Pod Identity Agents are DaemonSets.<br/>
  This means they **cannot** run on Fargate hosts and **will** require EC2 nodes.
- Does **not** work with **Amazon-provided EKS add-ons** that need IAM credentials.<br/>
  These controllers, drivers and plugins support EKS Pod Identities should they be installed as **self-managed** add-ons
  instead.

Requirements:

- The **nodes**' service role **must** have permissions for the agent to execute `AssumeRoleForPodIdentity` actions in
  the EKS Auth API.

  Use the AWS-managed `AmazonEKSWorkerNodePolicy` policy.<br/>
  Alternatively, add a custom policy with the following:

  ```json
  {
      "Version": "2012-10-17",
      "Statement": [{
          "Effect": "Allow",
          "Action": [ "eks-auth:AssumeRoleForPodIdentity" ],
          "Resource": "*"
      }]
  }
  ```

  Limit this action using tags to restrict which roles can be assumed by pods that use the agent.

- Nodes **must** be able to reach and download images from ECRs.<br/>
  Required since the container image for the add-on is available there.
- Nodes **must** be able to reach the EKS Auth API.<br/>
  Private clusters **will** require the `eks-auth` endpoint in PrivateLink.

Procedure:

1. Set up the Pod Identity Agent on clusters.

   <details>
     <summary>CLI</summary>

   ```sh
   aws eks create-addon --cluster-name 'DeepThought' --addon-name 'eks-pod-identity-agent'
   aws eks create-addon … --resolve-conflicts 'OVERWRITE'
   ```

   </details>

   <details style="margin-bottom: 1em">
     <summary>Pulumi</summary>

   ```ts
   new aws.eks.Addon(
       "pod-identity",
       {
           clusterName: cluster.name,
           addonName: "eks-pod-identity-agent",
           resolveConflictsOnCreate: "OVERWRITE",
           resolveConflictsOnUpdate: "OVERWRITE",
       },
   );
   ```

   </details>

1. Associate IAM roles with Kubernetes service accounts.

   There is **no need** for the service account to exists before association.<br/>
   The moment it will be created in the defined namespace, it will also be able to assume the role.

   <details>
     <summary>CLI</summary>

   ```sh
   aws eks create-pod-identity-association \
     --cluster-name 'DeepThought' --namespace 'default' \
     --service-account 'cluster-autoscaler-aws' --role-arn 'arn:aws:iam::012345678901:role/EKSScaleNodeGroupsPolicy'
   ```

   </details>

   <details style="margin-bottom: 1em">
     <summary>Pulumi</summary>

   ```ts
   new aws.eks.PodIdentityAssociation(
       "customRole-to-defaultServiceAccount",
       {
           clusterName: cluster.name,
           roleArn: customRole.arn,
           serviceAccount: "default",
           namespace: "default",
       },
   );
   ```

   </details>

1. Configure pods to use those service accounts.

### Cluster autoscaler

Just use the [Kubernetes' cluster autoscaler component].

Suggested the use of a custom IAM role and [Pod Identity].<br/>
Refer the autoscaler's
[AWS-specific README](https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md).

<details>
  <summary>Assume role policy definition</summary>

  ```json
  {
      "Version": "2012-10-17",
      "Statement": [{
          "Effect": "Allow",
          "Principal": {
              "Service": "pods.eks.amazonaws.com"
          },
          "Action": [
              "sts:AssumeRole",
              "sts:TagSession"
          ]
      }]
  }
  ```

</details>

<details style="margin-bottom: 1em">
  <summary>Pulumi</summary>

```ts
const clusterAutoscaling_role = new aws.iam.Role(
    "clusterAutoscaling",
    {
        description: "Allows Pods to scale EKS cluster node groups on behalf of the user.",
        assumeRolePolicy: clusterAutoscaler_assumeRole_policy,
    },
);
const clusterAutoscaling_policy_eksScaleNodeGroups = new aws.iam.Policy(
    "eksScaleNodeGroups",
    {
        description: "Allows bearers to scale EKS node groups up and down.",
        policy: JSON.stringify({
            Version: "2012-10-17",
            Statement: [
                {
                    Effect: "Allow",
                    Action: [
                        "autoscaling:DescribeAutoScalingGroups",
                        "autoscaling:DescribeAutoScalingInstances",
                        "autoscaling:DescribeLaunchConfigurations",
                        "autoscaling:DescribeScalingActivities",
                        "ec2:DescribeImages",
                        "ec2:DescribeInstanceTypes",
                        "ec2:DescribeLaunchTemplateVersions",
                        "ec2:GetInstanceTypesFromInstanceRequirements",
                        "eks:DescribeNodegroup",
                    ],
                    Resource: [ "*" ],
                },
                {
                    Effect: "Allow",
                    Action: [
                        "autoscaling:SetDesiredCapacity",
                        "autoscaling:TerminateInstanceInAutoScalingGroup",
                    ],
                    Resource: [ "*" ],
                },
            ],
        }),
    },
);
new aws.iam.RolePolicyAttachment(
    "scaleNodeGroupsPolicy-to-clusterAutoscalingRole",
    {
        policyArn: clusterAutoscaling_policy_scaleNodeGroups.arn,
        role: clusterAutoscaling_role.name,
    },
);
new aws.eks.PodIdentityAssociation(
    "clusterAutoscalingRole-to-clusterAutoscalerServiceAccount",
    {
        clusterName: cluster.name,
        roleArn: clusterAutoscaling_role.arn,
        serviceAccount: "cluster-autoscaler-aws",
        namespace: "kube-system",
    },
);
```

</details>

Install the cluster autoscaler component with the proper configuration:

```sh
# Use a service account with podIdentityAssociation
aws eks --region 'eu-west-1' update-kubeconfig --name 'DeepThought'
helm upgrade -i --repo 'https://kubernetes.github.io/autoscaler' \
  'cluster-autoscaler' 'cluster-autoscaler' \
  --namespace 'kube-system' \
  --set 'cloudProvider'='aws' \
  --set 'awsRegion'='eu-west-1' \
  --set 'autoDiscovery.clusterName'='DeepThought' \
  --set 'rbac.serviceAccount.name'='cluster-autoscaler-aws'
```

After any operation, the cluster autoscaler will wait for the ASG cooldown time to end.<br/>
Only then, it will start counting down its own timers.

### AWS Load Balancer Controller

Refer [Install the AWS Load Balancer Controller using Helm].

Requirements:

- An existing EKS cluster (_duh!_).
- An existing IAM [OIDC provider][oidc providers] for the cluster.<br/>
  Alternatively, [Pod Identity] must be installed in the cluster and the role in the next step must be configured to
  use it.
- A dedicated IAM role for the load balancer controller.

  <details style="margin-bottom: 1em">
    <summary>Pulumi (OIDC)</summary>

  ```ts
  const eksElbController_role = oidcProvider.arn.apply(oidcProviderArn => new aws.iam.Role(
      "eksElbController",
      {
          name: "EksElbControllerRole",
          description: "Allows EKS' load balancer controller component to control ELBs on behalf of the user.",
          assumeRolePolicy: JSON.stringify({
              Version: "2012-10-17",
              Statement: [{
                  Effect: "Allow",
                  Principal: {
                      Federated: oidcProviderArn,
                  },
                  Action: "sts:AssumeRoleWithWebIdentity",
                  Condition: {
                      StringEquals: {
                          // FIXME: use references
                          "oidc.eks.eu-west-1.amazonaws.com/id/0123456789ABCDEF0123456789ABCDEF:aud": "sts.amazonaws.com",
                          "oidc.eks.eu-west-1.amazonaws.com/id/0123456789ABCDEF0123456789ABCDEF:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller",
                      },
                  },
              }],
          }),
      },
  ));
  new aws.iam.RolePolicyAttachment(
      "eksElbControllerPolicy-to-eksElbControllerRole",
      {
          policyArn: "arn:aws:iam::012345678901:policy/EksElbControllerPolicy",
          role: eksElbController_role.name,
      },
  );
  ```

   </details>

- Subnets **must** be configured _properly_.<br/>
  Refer [Route application and HTTP traffic with Application Load Balancers].

  Specifically, subnets must have the specific, appropriate tags.<br/>
  Those are actively looked for by the controller, and will miserably fail if they are not present.

Procedure:

1. Create a IAM policy using the `/docs/install/iam_policy.json` file in the
   [controller's repository][aws load balancer controller repository].

   <details style="margin-bottom: 1em">
     <summary>CLI</summary>

   ```sh
   curl -O 'https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.8.1/docs/install/iam_policy.json'
   aws iam create-policy \
     --policy-name 'EksElbControllerPolicy' \
     --policy-document 'file://iam_policy.json'
   ```

   </details>

1. Assign the policy from the previous step to the role.
1. Install the load balancer controller with the proper configuration.

   <details style="margin-bottom: 1em">
     <summary>Helm</summary>

   ```sh
   helm upgrade -i --repo 'https://aws.github.io/eks-charts' \
     'aws-load-balancer-controller' 'aws-load-balancer-controller' \
     --namespace 'kube-system' \
     --set 'clusterName'='DeepThought' \
     --set 'serviceAccount.create'='true' \
     --set 'serviceAccount.name'='aws-load-balancer-controller' \
     --set 'region'='eu-west-1' \
     --set 'vpcId'='vpc-01234567'
   ```

   </details>

### EBS CSI driver

#### EBS CSI driver as aws-managed add-on

Refer [Manage the Amazon EBS CSI driver as an Amazon EKS add-on].

Requirements:

- An existing EKS cluster (_duh!_).
- An existing IAM [OIDC provider][oidc providers] for the cluster.<br/>
  Alternatively, [Pod Identity] must be installed in the cluster and the role in the next step must be configured to
  use it.
- An IAM role for the EBS CSI driver.<br/>
  Refer [Create an Amazon EBS CSI driver IAM role].

  If missing, the add-on **will** be installed but `kubectl describe pvc` will show the following errors:

  > ```plaintext
  > failed to provision volume with StorageClass
  > ```
  >
  > ```plaintext
  > could not create volume in EC2: UnauthorizedOperation error
  > ```

  <details style="margin-bottom: 1em">
    <summary>Pulumi</summary>

  ```ts
  const eksEbsCsiDriver_role = oidcProvider.arn.apply(oidcProviderArn => new aws.iam.Role(
      "eksEbsCsiDriver",
      {
          name: "EksEbsCsiDriverRole",
          description: "Allows Pods to act upon EBS volumes on behalf of the user.",
          assumeRolePolicy: JSON.stringify({
              Version: "2012-10-17",
              Statement: [{
                  Effect: "Allow",
                  Principal: {
                      Federated: oidcProviderArn,
                  },
                  Action: "sts:AssumeRoleWithWebIdentity",
                  Condition: {
                      StringEquals: {
                          // FIXME: use references
                          "oidc.eks.eu-west-1.amazonaws.com/id/0123456789ABCDEF0123456789ABCDEF:aud": "sts.amazonaws.com",
                          "oidc.eks.eu-west-1.amazonaws.com/id/0123456789ABCDEF0123456789ABCDEF:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa",
                      },
                  },
              }],
          }),
      },
  ));
  new aws.iam.RolePolicyAttachment(
      "AmazonEBSCSIDriverPolicy-to-eksEbsCsiDriverRole",
      {
          policyArn: "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
          role: eksEbsCsiDriver_role.name,
      },
  );
  ```

  </details>

- [external-snapshotter], if planning to use the snapshot functionality of the driver.<br/>
  The components' installation **must** be performed in this order:

  1. CustomResourceDefinitions (CRDs) for `volumeSnapshotClasses`, `volumeSnapshots` and `volumeSnapshotContents`.
  1. ClusterRole, ClusterRoleBinding, and other RBAC components.
  1. Snapshot controller's Deployment.

  <details style="margin-bottom: 1em">
    <summary>CLI</summary>

  ```sh
  git clone 'https://github.com/kubernetes-csi/external-snapshotter.git'
  kubectl kustomize 'external-snapshotter/client/config/crd' | kubectl apply -f -
  kubectl -n 'kube-system' kustomize 'external-snapshotter/deploy/kubernetes/snapshot-controller' | kubectl apply -f -
  ```

  </details>

Procedure:

- Install the add-on.<br/>
  Make sure to specify the IAM role for the EBS CSI driver from the requirements.

  <details>
    <summary>CLI</summary>

  ```sh
  aws eks create-addon --cluster-name 'DeepThought' \
    --addon-name 'aws-ebs-csi-driver' \
    --service-account-role-arn 'arn:aws:iam::012345678901:role/customEksEbsCsiDriverRole
  ```

  </details>

  <details style="margin-bottom: 1em">
    <summary>Pulumi</summary>

  ```ts
  new aws.eks.Addon(
      "ebsCsiDriver",
      {
          clusterName: cluster.name,
          addonName: "aws-ebs-csi-driver",
          addonVersion: "v1.32.0-eksbuild.1",
          resolveConflictsOnCreate: "OVERWRITE",
          resolveConflictsOnUpdate: "OVERWRITE",
          serviceAccountRoleArn: ebsCsiDriver_role.arn,
      },
  );
  ```

  </details>

#### EBS CSI driver as self-managed add-on

<details style="margin-bottom: 1em">
  <summary>CLI</summary>

```sh
helm upgrade -i --repo 'https://kubernetes-sigs.github.io/aws-ebs-csi-driver' \
  'aws-ebs-csi-driver' 'aws-ebs-csi-driver' \
  --namespace 'kube-system'
```

</details>

## Troubleshooting

See [Amazon EKS troubleshooting].

### Identify common issues

Use the [AWSSupport-TroubleshootEKSWorkerNode runbook].

> For the automation to work, worker nodes **must** have permission to access Systems Manager and have Systems Manager
> running.<br/>
> Grant this permission by attaching the `AmazonSSMManagedInstanceCore` policy to the node role.<br/>
> See [Configure instance permissions required for Systems Manager].

Procedure:

1. Open the [AWSSupport-TroubleshootEKSWorkerNode runbook].
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

### AWS ELB controller fails to get the region from the host's metadata

Error message example:

> failed to introspect region from EC2Metadata, specify --aws-region instead if EC2Metadata is unavailable:
> EC2MetadataRequestError: failed to get EC2 instance identity document

Root cause: there is something wrong with the role and its permissions.

Workaround:<br/>
Provide the helm chart values for vpcId and region:

```sh
helm upgrade -i --repo 'https://aws.github.io/eks-charts' \
  'aws-load-balancer-controller' 'aws-load-balancer-controller' \
  […] \
  --set 'region'='us-west-1' \
  --set 'vpcId'='vpc-01234567'
```

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
- [Use Amazon EBS storage]

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
- [Visualizing AWS EKS Kubernetes Clusters with Relationship Graphs]
- [How to Add IAM User and IAM Role to AWS EKS Cluster?]
- [Amazon Elastic Block Store (EBS) CSI driver]
- [Manage the Amazon EBS CSI driver as an Amazon EKS add-on]
- [How do you get kubectl to log in to an AWS EKS cluster?]
- [Learn how EKS Pod Identity grants pods access to AWS services]
- [Configure instance permissions required for Systems Manager]
- [View resource usage with the KubernetesMetrics Server]
- [Create an Amazon EBS CSI driver IAM role]
- [Migrating Amazon EKS clusters from gp2 to gp3 EBS volumes]
- [Upgrade default storage class for EKS]
- [Enable EBS GP3 for eks by default]
- [Install the AWS Load Balancer Controller using Helm]
- [Reaching failed to introspect region from EC2Metadata... on container start-up - vanilla EKS/Fargate]
- [Route application and HTTP traffic with Application Load Balancers]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[access management]: #access-management
[cluster autoscaler]: #cluster-autoscaler
[create worker nodes]: #create-worker-nodes
[ebs csi driver as aws-managed add-on]: #ebs-csi-driver-as-aws-managed-add-on
[identify common issues]: #identify-common-issues
[oidc providers]: #oidc-providers
[pod identity]: #pod-identity
[requirements]: #requirements
[secrets encryption through kms]: #secrets-encryption-through-kms

<!-- Knowledge base -->
[amazon web services]: README.md
[cli]: cli.md
[control plane]: ../../kubernetes/README.md#control-plane
[kubernetes' cluster autoscaler component]: ../../kubernetes/cluster%20autoscaler.md
[ebs]: ebs.md
[karpenter]: ../../kubernetes/karpenter.placeholder
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
[awssupport-troubleshooteksworkernode runbook]: https://docs.aws.amazon.com/systems-manager-automation-runbooks/latest/userguide/automation-awssupport-troubleshooteksworkernode.html
[choosing an amazon ec2 instance type]: https://docs.aws.amazon.com/eks/latest/userguide/choosing-instance-type.html
[configure instance permissions required for systems manager]: https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-profile.html#instance-profile-policies-overview
[create an amazon ebs csi driver iam role]: https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html
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
[install the aws load balancer controller using helm]: https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html
[learn how eks pod identity grants pods access to aws services]: https://docs.aws.amazon.com/eks/latest/userguide/pod-identities.html
[manage the amazon ebs csi driver as an amazon eks add-on]: https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html
[managed node groups]: https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html
[migrating amazon eks clusters from gp2 to gp3 ebs volumes]: https://aws.amazon.com/blogs/containers/migrating-amazon-eks-clusters-from-gp2-to-gp3-ebs-volumes/
[private cluster requirements]: https://docs.aws.amazon.com/eks/latest/userguide/private-clusters.html
[required permissions to view eks resources]: https://docs.aws.amazon.com/eks/latest/userguide/view-kubernetes-resources.html#view-kubernetes-resources-permissions
[route application and http traffic with application load balancers]: https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
[running stateful workloads with amazon eks on aws fargate using amazon efs]: https://aws.amazon.com/blogs/containers/running-stateful-workloads-with-amazon-eks-on-aws-fargate-using-amazon-efs/
[self-managed nodes]: https://docs.aws.amazon.com/eks/latest/userguide/worker.html
[service-linked role permissions for amazon eks]: https://docs.aws.amazon.com/eks/latest/userguide/using-service-linked-roles-eks.html#service-linked-role-permissions-eks
[simplified amazon eks access - new cluster access management controls]: https://www.youtube.com/watch?v=ae25cbV5Lxo
[use amazon ebs storage]: https://docs.aws.amazon.com/eks/latest/userguide/ebs-csi.html
[using iam groups to manage kubernetes cluster access]: https://archive.eksworkshop.com/beginner/091_iam-groups/
[using service-linked roles for amazon eks]: https://docs.aws.amazon.com/eks/latest/userguide/using-service-linked-roles.html
[view resource usage with the kubernetesmetrics server]: https://docs.aws.amazon.com/eks/latest/userguide/metrics-server.html

<!-- Others -->
[amazon elastic block store (ebs) csi driver]: https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/README.md
[aws load balancer controller repository]: https://github.com/kubernetes-sigs/aws-load-balancer-controller
[enable ebs gp3 for eks by default]: https://geko.cloud/en/aws-enable-ebs-gp3-for-eks-by-default/
[external-snapshotter]: https://github.com/kubernetes-csi/external-snapshotter
[how do you get kubectl to log in to an aws eks cluster?]: https://stackoverflow.com/questions/53266960/how-do-you-get-kubectl-to-log-in-to-an-aws-eks-cluster
[how to add iam user and iam role to aws eks cluster?]: https://antonputra.com/kubernetes/add-iam-user-and-iam-role-to-eks/
[reaching failed to introspect region from ec2metadata... on container start-up - vanilla eks/fargate]: https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/1561
[upgrade default storage class for eks]: https://www.argonaut.dev/docs/guides/migrate-eks-to-gp3
[visualizing aws eks kubernetes clusters with relationship graphs]: https://dev.to/aws-builders/visualizing-aws-eks-kubernetes-clusters-with-relationship-graphs-46a4
