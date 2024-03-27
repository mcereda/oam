/**
 * Follows https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html.
 * Multiple methods of creating EKS clusters at some point try to create 2
 * CloudFormation stacks.
 * The fock, AWS? (╯°Д°)╯︵/(.□ . \)
 *
 * Minimum resource requirements
 * -----------------------------------------------------------------------------
 * - IAM service roles:
 *     - 1 to manage the cluster, with 'AmazonEKSClusterPolicy' policy
 *     - 1 to manage EC2 worker nodes (if using them), with policies
 *         - 'AmazonEKS_CNI_Policy'
 *         - 'AmazonEKSWorkerNodePolicy'
 *         - 'AmazonEC2ContainerRegistryReadOnly'
 *         - 'AmazonSSMManagedInstanceCore' (optional, for troubleshooting)
 *     - 1 to manage fargate resources (if using them), with
 *       'AmazonEKSFargatePodExecutionRolePolicy' policy
 * - The control plane
 * - 1 executor for pods (EC2, managed EC2 or Fargate)
 * - 1 access entry with assigned EKS access policy (if using APIs for
 *   authentication)
 **/

import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

const callerIdentity = aws.getCallerIdentity({});
const subnetIds = [
    "subnet-0123456789abcdef0",  // private, eu-west-1a
    "subnet-123456789abcdef01",  // private, eu-west-1b
];


/**
 * Custom Cluster Service Role
 * -----------------------------------------------------------------------------
 * Required to use other AWS resources (the KMS key for encryption).
 * Intended to be only used by this cluster.
 * Creation took 1s on average.
 * Deletion took 1s on average.
 **/

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

const cluster_serviceRole_role = new aws.iam.Role("cluster-serviceRole-role", {
    description: "Allows EKS to manage clusters on behalf of the user.",
    tags: {
        Description: "EKS cluster service role",
        EksComponent: "Cluster service role",
        RoleType: "ServiceRole",
    },

    assumeRolePolicy: cluster_assumeRole_policy,
});

const cluster_serviceRole_rolePolicyAttachment = new aws.iam.RolePolicyAttachment("cluster-serviceRole-rolePolicyAttachment", {
    role: cluster_serviceRole_role.name,
    policyArn: "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
});


/**
 * Cluster.
 * Better defined as the control plane and its dedicated nodes.
 * -----------------------------------------------------------------------------
 * Gotchas:
 * - 'vpcConfig.clusterSecurityGroupId' cannot be customized.
 *   Should one try and set it, one will get the following error message:
 *   'error: aws:eks/cluster:Cluster resource 'cluster' has a problem: Value for
 *   unconfigurable attribute. Can't configure a value for
 *   "vpc_config.0.cluster_security_group_id": its value will be decided
 *   automatically based on the result of applying this configuration.'
 * Creation took 426s on average (382, 402, 454, 423, 371, 523, 422).
 * Deletion took 167s on average (70, 125, 149, 167, 320, 167).
 **/

const k8s_version = "1.29"  // https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html

const cluster = new aws.eks.Cluster("cluster", {
    tags: {
        Description: "Test EKS cluster",
        EksComponent: "Control Plane and associated nodes",
    },

    vpcConfig: {
        subnetIds: subnetIds,
        endpointPrivateAccess: true,
    },
    version: k8s_version,
    roleArn: cluster_serviceRole_role.arn,
    accessConfig: {
        authenticationMode: "API",
    },
    enabledClusterLogTypes: [
        // https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
        // "api",
        // "audit",
        // "authenticator",
        // "controllerManager",
        // "scheduler",
    ],
});


/**
 * Access management.
 * ------------------
 * Refer to https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html.
 * Creation took 1s on average.
 * Deletion took 1s on average.
 **/

const cluster_admin_accessEntry = new aws.eks.AccessEntry("cluster-admin-accessEntry", {
    clusterName: cluster.name,

    principalArn: callerIdentity.then(callerIdentity => callerIdentity.arn),  // only users or roles, no groups
    kubernetesGroups: [
        // No 'system:…', 'amazon:…', 'aws:…', 'eks:…' nor 'iam:…'.
        // See reference page.
    ],
});

const cluster_admin_accessPolicyAssociation = new aws.eks.AccessPolicyAssociation("cluster-admin-accessPolicyAssociation", {
    clusterName: cluster.name,
    policyArn: "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy",
    principalArn: callerIdentity.then(callerIdentity => callerIdentity.arn),
    accessScope: {
        type: "cluster",
    },
});


/**
 * Custom EC2 Worker Node Service Role
 * -----------------------------------------------------------------------------
 * Required to use EC2 instances as worker nodes.
 * Intended to be only used by this cluster.
 * Creation took 1s on average.
 * Deletion took 1s on average.
 **/

const node_assumeRole_policy = JSON.stringify({
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
    description: "Allows EKS to manage EC2 instances on behalf of the user.",
    tags: {
        Description: "EC2 node service role",
        EksComponent: "EC2 node service role",
        RoleType: "ServiceRole",
    },

    assumeRolePolicy: node_assumeRole_policy,
});

const node_service_rolePolicyAttachment_cni = new aws.iam.RolePolicyAttachment("node-service-rolePolicyAttachment-cni", {
    role: node_service_role.name,
    policyArn: "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
});
const node_service_rolePolicyAttachment_ecr = new aws.iam.RolePolicyAttachment("node-service-rolePolicyAttachment-ecr", {
    role: node_service_role.name,
    policyArn: "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
});
const node_service_rolePolicyAttachment_workerNode = new aws.iam.RolePolicyAttachment("node-service-rolePolicyAttachment-workerNode", {
    role: node_service_role.name,
    policyArn: "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
});

// SSM and troubleshooting
const node_service_rolePolicyAttachment_ssm = new aws.iam.RolePolicyAttachment("node-service-rolePolicyAttachment-ssm", {
    role: node_service_role.name,
    policyArn: "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
});


/**
 * EC2 worker nodes
 * -----------------------------------------------------------------------------
 * Creation took 102s on average (86, 117) with dedicated (non-SPOT) instances.
 * Deletion took 286s on average (153, 136, 136, 136, 502, 502, 431).
 **/

const nodeGroup = new aws.eks.NodeGroup("nodeGroup", {
    clusterName: cluster.name,
    tags: {
        Description: "EC2 node group",
        EksComponent: "EC2 node group",
    },

    nodeRoleArn: node_service_role.arn,
    subnetIds: cluster.vpcConfig.subnetIds,
    capacityType: "SPOT",
    instanceTypes: [
        // https://docs.aws.amazon.com/eks/latest/userguide/choosing-instance-type.html
        // https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html#AvailableInstanceTypes
        "t3a.medium",
        "t3.medium",
    ],
    scalingConfig: {
        minSize: 1,
        maxSize: 3,
        desiredSize: 2,
    },
    updateConfig: {
        // either the number OR the percentage
        // maxUnavailable: 1,
        maxUnavailablePercentage: 50,
    },
});


/**
 * Custom Fargate Service Role
 * -----------------------------------------------------------------------------
 * Required to use Fargate as worker node.
 * Intended to be only used by this cluster.
 * Creation took 1s on average.
 * Deletion took 1s on average.
 **/
const regionOutput = aws.getRegionOutput({});
const sourceArnOutput = pulumi.all([
    callerIdentity.then(callerIdentity => callerIdentity.accountId),
    cluster.name,
    regionOutput.apply(region => region.id),
]).apply(([
    accountId,
    clusterName,
    regionId,
]) => `arn:aws:eks:${regionId}:${accountId}:fargateprofile/${clusterName}/*`);

const fargate_serviceRole_role = new aws.iam.Role("fargate-service-role", {
    description: "Allows EKS to manage fargate pods on behalf of the user.",
    tags: {
        Description: "EC2 fargate service role",
        EksComponent: "EC2 fargate service role",
        RoleType: "ServiceRole",
    },

    assumeRolePolicy: sourceArnOutput.apply(sourceArn => JSON.stringify({
        Version: "2012-10-17",
        Statement: [{
            Effect: "Allow",
            Action: "sts:AssumeRole",
            Principal: {
                Service: "eks-fargate-pods.amazonaws.com",
            },
            Condition: {
                ArnLike: {
                    "aws:SourceArn": sourceArn,
                }
            },
        }],
    })),
});

const fargate_serviceRole_rolePolicyAttachment = new aws.iam.RolePolicyAttachment("fargate-serviceRole-rolePolicyAttachment", {
    role: fargate_serviceRole_role.name,
    policyArn: "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy",
});


/**
 * Fargate profile
 * -----------------------------------------------------------------------------
 * Creation took 98s on average (93, 76, 123).
 * Deletion took 105s on average (82, 95, 146, 95).
 **/

const fargateProfile = new aws.eks.FargateProfile("fargateProfile", {
    clusterName: cluster.name,
    tags: {
        Description: "Fargate profile",
        EksComponent: "Fargate profile",
    },

    podExecutionRoleArn: fargate_serviceRole_role.arn,
    subnetIds: cluster.vpcConfig.subnetIds,
    selectors: [
        { namespace: "default" },
        { namespace: "kube-system" },
    ],
});
