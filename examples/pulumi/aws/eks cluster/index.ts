/**
 * EKS cluster the manual way.
 * -------------------------------------
 * Follows <https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html>, then includes some
 * improvements from personal experience.
 *
 * No tooling magic, keep everything in plain sight.
 * Multiple suggested methods of creating EKS clusters leverage `eksctl` at some point and / or try to create 2 or more
 * CloudFormation stacks. What the actual fuck, AWS? (╯°Д°)╯︵/(.□ . \)
 *
 * Features:
 *   - Private cluster.
 *   - Log everything to CloudWatch.
 *   - Use KMS to encrypt secrets.
 *   - Use Roles for administration and viewing.
 *   - Use EC2 instances as nodes.
 *   - Use Fargate as node.
 *   - Use addons:
 *       - Pod Identity.
 *         Requires EC2 instances, not supported by Fargate at the time of writing.
 *       - ClusterAutoscaler.
 *         Requires Pod Identity.
 *       - Metrics Server.
 *
 * Minimum resource requirements:
 *   - IAM service roles:
 *       - 1 for the cluster, with the 'AmazonEKSClusterPolicy' policy
 *       - 1 for the EC2 worker nodes (if using them), with the following policies:
 *           - 'AmazonEKS_CNI_Policy'
 *           - 'AmazonEKSWorkerNodePolicy'
 *           - 'AmazonEC2ContainerRegistryReadOnly'
 *           - 'AmazonSSMManagedInstanceCore' (optional, for troubleshooting)
 *       - 1 for fargate resources (if using them), with the 'AmazonEKSFargatePodExecutionRolePolicy' policy
 *   - The control plane
 *   - 1 executor for pods (EC2, managed EC2 or Fargate)
 *   - 1 access entry with assigned EKS access policy (if using APIs for authentication)
 **/

import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as k8s from "@pulumi/kubernetes";
import * as yaml from "yaml";

const awsRegionId_output = aws.getRegionOutput().id;
const awsAccountId_output = aws.getCallerIdentityOutput().accountId;

/**
 * Step 0: gather or create requirements.
 * -------------------------------------
 * - Administrative IAM Role.
 * - Viewing IAM Role.
 * - Subnets information.
 * - KMS encryption key.
 *   Only required for secrets management integration with KMS.
 *
 * Creation took 1s on average each.
 * Deletion took 1s on average each.
 **/

const clusterAdmin_iamRole_output = awsAccountId_output.apply(
    (accountId: string) => new aws.iam.Role(
        "clusterAdmin",
        {
            description: "Allows administering the EKS cluster.",
            tags: {
                eksComponent: "administrative user",
                iamRoleType: "user",
            },
            assumeRolePolicy: JSON.stringify({
                Version: "2012-10-17",
                Statement: [{
                    Sid: "AllowAssumingThisVeryRole",
                    Effect: "Allow",
                    Principal: {
                        AWS: `arn:aws:iam::${accountId}:root`,
                    },
                    Action: "sts:AssumeRole",
                }],
            }),
        },
    ),
);
pulumi.all([clusterAdmin_iamRole_output.arn, clusterAdmin_iamRole_output.name]).apply(
    ([roleArn, roleName]: [aws.ARN, string]) => new aws.iam.Policy(
        "clusterAdmin-assumeRole",
        {
            description: `Allows bearers to try and assume the ${roleName} role`,
            policy: JSON.stringify({
                Version: "2012-10-17",
                Statement: [{
                    Sid: "AllowAssumingTheClusterAdminRole",
                    Effect: "Allow",
                    Action: "sts:AssumeRole",
                    Resource: roleArn,
                }],
            }),
        },
    ),
);

const clusterViewer_iamRole_output = awsAccountId_output.apply(
    (accountId: string) => new aws.iam.Role(
        "clusterViewer",
        {
            description: "Allows browsing the EKS cluster.",
            tags: {
                eksComponent: "viewing user",
                iamRoleType: "user",
            },
            assumeRolePolicy: JSON.stringify({
                Version: "2012-10-17",
                Statement: [{
                    Sid: "AllowAssumingThisVeryRole",
                    Effect: "Allow",
                    Principal: {
                        AWS: `arn:aws:iam::${accountId}:root`,
                    },
                    Action: "sts:AssumeRole",
                }],
            }),
        },
    ),
);
pulumi.all([clusterViewer_iamRole_output.arn, clusterViewer_iamRole_output.name]).apply(
    ([roleArn, roleName]: [aws.ARN, string]) => new aws.iam.Policy(
        "clusterViewer-assumeRole",
        {
            description: `Allows bearers to try and assume the ${roleName} role`,
            policy: JSON.stringify({
                Version: "2012-10-17",
                Statement: [{
                    Sid: "AllowAssumingTheClusterViewerRole",
                    Effect: "Allow",
                    Action: "sts:AssumeRole",
                    Resource: roleArn,
                }],
            }),
        },
    ),
);

// -------

const privateSubnets_output = aws.ec2.getSubnetsOutput({
    filters: [{
        name: "tag:scope",
        values: [ "private" ],
    }],
});

// -------

const encryption_key = new aws.kms.Key(
    "encryption",
    {
        description: "Encryption key for EKS clusters.",
        deletionWindowInDays: 7,  // 7 to 30 inclusive
        tags: {
            eksComponent: "secrets management",
        },
    },
);

/**
 * Step 1: create the cluster's control plane.
 * -------------------------------------
 * The 'cluster' service role can be *non* cluster-specific.
 *
 * 1. Create the 'cluster' service role.
 *    Requires the 'AmazonEKSClusterPolicy' AWS-managed policy or similar permissions.
 *    Requires being able to use the encryption key for secrets management integration.
 * 2. Create the Cluster resource (A.K.A. the cluster's control plane).
 * 3. Allow access to the admin and viewer IAM Roles.
 *    Refer <https://docs.aws.amazon.com/eks/latest/userguide/access-entries.html>.
 * 4. Create a Pulumi Kubernetes provider to enable access to helm, kustomize and other tools.
 *
 * Gotchas:
 *   - 'vpcConfig.clusterSecurityGroupId' cannot be customized.
 *     Should one try and set it, one will get the following error message:
 *       error: aws:eks/cluster:Cluster resource 'cluster' has a problem: Value for unconfigurable attribute. Can't
 *       configure a value for "vpc_config.0.cluster_security_group_id": its value will be decided automatically
 *       based on the result of applying this configuration.
 *
 * Creation took 426s on average (382, 402, 454, 423, 371, 523, 422).
 * Deletion took 167s on average (70, 125, 149, 167, 320, 167).
 **/

const clusterServiceRole_iamRole = new aws.iam.Role(
    "clusterServiceRole",
    {
        description: "Allows EKS to manage clusters on behalf of the user.",
        tags: {
            eksComponent: "cluster service role",
            iamRoleType: "service",
        },
        assumeRolePolicy: JSON.stringify({
            Version: "2012-10-17",
            Statement: [{
                Effect: "Allow",
                Principal: {
                    Service: "eks.amazonaws.com",
                },
                Action: "sts:AssumeRole",
            }],
        }),
    },
);
encryption_key.arn.apply(
    (keyArn: aws.ARN) => new aws.iam.RolePolicy(
        "clusterServiceRole",
        {
            role: clusterServiceRole_iamRole,
            name: "AllowRoleFunctions",
            policy: JSON.stringify({
                Version: "2012-10-17",
                Statement: [{
                    Sid: "UseKmsForSecretsManagement",
                    Effect: "Allow",
                    Action: [
                        "kms:CreateGrant",
                        "kms:DescribeKey",
                    ],
                    Resource: keyArn,
                }],
            }),
        },
    ),
);
new aws.iam.RolePolicyAttachment(
    "AmazonEKSClusterPolicy-to-clusterServiceRole",
    {
        policyArn: "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
        role: clusterServiceRole_iamRole.name,
    },
);

// -------

const cluster = pulumi.all([privateSubnets_output.ids, clusterServiceRole_iamRole.arn, encryption_key.arn]).apply(
    ([privateSubnetIds, clusterServiceRoleArn, encryptionKeyArn]: [string[], aws.ARN, aws.ARN]) => new aws.eks.Cluster(
        "cluster",
        {
            tags: {
                eksComponent: "control plane",
            },
            vpcConfig: {
                subnetIds: privateSubnetIds,
                endpointPrivateAccess: true,
            },
            version: "1.30",
            roleArn: clusterServiceRoleArn,
            accessConfig: {
                authenticationMode: "API_AND_CONFIG_MAP",
            },
            encryptionConfig: {
                provider: {
                    keyArn: encryptionKeyArn,
                },
                resources: [ "secrets" ],
            },
            enabledClusterLogTypes: [
                // https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
                "api",
                "audit",
                "authenticator",
                "controllerManager",
                "scheduler",
            ],
            upgradePolicy: {
                supportType: "STANDARD",
            },
        },
        { deleteBeforeReplace: true },
    ),
);

// -------

const clusterAdmins: pulumi.Output<aws.iam.Role>[] = [
    clusterAdmin_iamRole_output.apply(role => role),
];
clusterAdmins.forEach(
    (iamRole_output: pulumi.Output<aws.iam.Role>) => {
        pulumi.all([iamRole_output.arn, iamRole_output.name]).apply(
            ([iamRoleArn, iamRoleName]: [aws.ARN, string]) => {
                const accessEntry = new aws.eks.AccessEntry(
                    `clusterAdmin-${iamRoleName}`,
                    {
                        clusterName: cluster.name,
                        principalArn: iamRoleArn,  // only users or roles, no groups
                    },
                );
                new aws.eks.AccessPolicyAssociation(
                    `AmazonEKSClusterAdminPolicy-to-${iamRoleName}`,
                    {
                        clusterName: cluster.name,
                        principalArn: accessEntry.principalArn,
                        policyArn: "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy",
                        accessScope: {
                            type: "cluster",
                        },
                    },
                );
            },
        );
    },
);

const clusterViewers: pulumi.Output<aws.iam.Role>[] = [
    clusterViewer_iamRole_output.apply(role => role),
];
clusterViewers.forEach(
    (iamRole_output: pulumi.Output<aws.iam.Role>) => {
        pulumi.all([iamRole_output.arn, iamRole_output.name]).apply(
            ([iamRoleArn, iamRoleName]: [aws.ARN, string]) => {
                const accessEntry = new aws.eks.AccessEntry(
                    `clusterViewer-${iamRoleName}`,
                    {
                        clusterName: cluster.name,
                        principalArn: iamRoleArn,  // only users or roles, no groups
                        kubernetesGroups: [
                            // No 'system:…', 'amazon:…', 'aws:…', 'eks:…' nor 'iam:…'.
                            // See reference page.
                        ],
                    },
                );
                new aws.eks.AccessPolicyAssociation(
                    `AmazonEKSAdminViewPolicy-to-${iamRoleName}`,
                    {
                        clusterName: cluster.name,
                        principalArn: accessEntry.principalArn,
                        policyArn: "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminViewPolicy",
                        accessScope: {
                            type: "cluster",
                        },
                    },
                );
            },
        );
    },
);

// -------

const kubeconfig_output = pulumi
    .all([
        cluster.arn,
        cluster.name,
        cluster.endpoint,
        cluster.certificateAuthorities[0],
        clusterAdmin_iamRole_output.arn,
        awsRegionId_output,
    ])
    .apply(
        ([
            clusterArn,
            clusterName,
            clusterEndpoint,
            clusterCertificateAuthority,
            roleArn,
            regionId,
        ]: [aws.ARN, string, string, aws.types.output.eks.ClusterCertificateAuthority, aws.ARN, string]) =>
            yaml.stringify({
                apiVersion: "v1",
                kind: "Config",
                preferences: {},
                clusters: [{
                    name: clusterArn,
                    cluster: {
                        server: clusterEndpoint,
                        "certificate-authority-data": clusterCertificateAuthority.data,
                    },
                }],
                users: [{
                    name: clusterArn,
                    user: {
                        exec: {
                            apiVersion: "client.authentication.k8s.io/v1beta1",
                            command: "aws",
                            args: [
                                "--output", "json",  // *must* output a JSON for the next step to work
                                "--region", regionId,
                                "eks",
                                    "get-token",
                                    "--cluster-name", clusterName,
                                    "--role-arn", roleArn,
                            ],
                        },
                    },
                }],
                contexts: [{
                    name: clusterArn,
                    context: {
                        cluster: clusterArn,
                        user: clusterArn,
                    },
                }],
                "current-context": clusterArn,
            }),
    );
const k8sProvider_output = kubeconfig_output.apply(
    (config: string) => new k8s.Provider(
        "cluster",
        { kubeconfig: config },
    ),
);

/**
 * Step 2a: create the cluster's EC2-backed worker nodes.
 * -------------------------------------
 * The 'worker node' service role can be *non* cluster-specific.
 *
 * 1. Create the 'worker node' service role.
 *    Requires the 'AmazonEKSWorkerNodePolicy', 'AmazonEKS_CNI_Policy' and 'AmazonEC2ContainerRegistryReadOnly'
 *    AWS-managed policies or similar permissions.
 *    If wanting SSM usage on the nodes, also requires the 'AmazonSSMManagedInstanceCore' AWS-managed policy or
 *    similar permissions (and the nodes must use an image that integrates with SSM).
 * 2. Create one or more node groups.
 *    Suggested 1 'core' group dedicated to addons and operators.
 **/

const nodeServiceRole_iamRole = new aws.iam.Role(
    "nodeServiceRole",
    {
        description: "Allows EKS to manage EC2 instances as worker nodes on behalf of the user.",
        tags: {
            eksComponent: "node service role",
            iamRoleType: "service",
        },
        assumeRolePolicy: JSON.stringify({
            Version: "2012-10-17",
            Statement: [{
                Effect: "Allow",
                Principal: {
                    Service: "ec2.amazonaws.com",
                },
                Action: "sts:AssumeRole",
            }],
        }),
    },
);
new aws.iam.RolePolicyAttachment(
    "AmazonEC2ContainerRegistryReadOnly-to-nodeServiceRole",
    {
        policyArn: "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        role: nodeServiceRole_iamRole.name,
    },
);
new aws.iam.RolePolicyAttachment(
    "AmazonEKS_CNI_Policy-to-nodeServiceRole",
    {
        policyArn: "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        role: nodeServiceRole_iamRole.name,
    },
);
new aws.iam.RolePolicyAttachment(
    "AmazonEKSWorkerNodePolicy-to-nodeServiceRole",
    {
        policyArn: "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        role: nodeServiceRole_iamRole.name,
    },
);
new aws.iam.RolePolicyAttachment(
    // SSM + troubleshooting
    "AmazonSSMManagedInstanceCore-to-nodeServiceRole",
    {
        role: nodeServiceRole_iamRole.name,
        policyArn: "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    },
);

// -------

new aws.eks.NodeGroup(
    "ec2WorkerNodes-core",
    {
        nodeGroupName: "core",
        clusterName: cluster.name,
        tags: {
            description: "addons and operators",
            eksCluster: cluster.name,
            eksComponent: "ec2-backed node group",
        },
        nodeRoleArn: nodeServiceRole_iamRole.arn,
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
    },
    {
        ignoreChanges: [
            "scalingConfig.desiredSize",  // autoscaling is enabled, see addons below
        ],
    },
);

/**
 * Step 2b: create the cluster's Fargate profile.
 * -------------------------------------
 * The 'fargate' service role can be *non* cluster-specific, but it would be better for it to be to contain costs.
 *
 * 1. Create the 'fargate' service role.
 *    Requires the 'AmazonEKSFargatePodExecutionRolePolicy', AWS-managed policy or similar permissions.
 * 2. Create one or more Fargate profiles.
 **/

const fargateSourceArn_output = pulumi.all([awsRegionId_output, awsAccountId_output, cluster.name]).apply(
    ([regionId, accountId, clusterName]: [string, string, string]) =>
        `arn:aws:eks:${regionId}:${accountId}:fargateprofile/${clusterName}/*`,
);

const fargateServiceRole_iamRole = fargateSourceArn_output.apply(
    (fargateSourceArn: string) => new aws.iam.Role(
        "fargateServiceRole",
        {
            description: "Allows EKS to manage Fargate-backed workloads on behalf of the user.",
            tags: {
                eksCluster: cluster.name,
                eksComponent: "fargate service role",
                iamRoleType: "service",
            },
            assumeRolePolicy: JSON.stringify({
                Version: "2012-10-17",
                Statement: [{
                    Effect: "Allow",
                    Principal: {
                        Service: "eks-fargate-pods.amazonaws.com",
                    },
                    Action: "sts:AssumeRole",
                    Condition: {
                        ArnLike: {
                            "aws:SourceArn": fargateSourceArn,
                        },
                    },
                }],
            }),
        },
    ),
);
new aws.iam.RolePolicyAttachment(
    "AmazonEKSFargatePodExecutionRolePolicy-to-fargateServiceRole",
    {
        policyArn: "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy",
        role: fargateServiceRole_iamRole.name,
    },
);

// -------

new aws.eks.FargateProfile(
    "fargateProfile-kubeSystem",
    {
        fargateProfileName: "kubeSystem",
        clusterName: cluster.name,
        tags: {
            eksCluster: cluster.name,
            eksComponent: "fargate profile",
        },
        podExecutionRoleArn: fargateServiceRole_iamRole.arn,
        subnetIds: cluster.vpcConfig.subnetIds,
        selectors: [
            { namespace: "kube-system" },
        ],
    },
);

/**
 * Step 3: install addons.
 * -------------------------------------
 * 1. Install AWS-managed addons.
 * 2. Install manually managed addons.
 **/

new aws.eks.Addon(
    "podIdentity",
    {
        clusterName: cluster.name,
        addonName: "eks-pod-identity-agent",
        addonVersion: "v1.3.2-eksbuild.2",
        resolveConflictsOnCreate: "OVERWRITE",
        resolveConflictsOnUpdate: "OVERWRITE",
    },
);

// -------

const clusterAutoscaler_iamRole = new aws.iam.Role(
    "clusterAutoscaler",
    {
        description: "Allows Pods to scale EKS cluster node groups on behalf of the user.",
        tags: {
            eksComponent: "pod service role",
            iamRoleType: "service",
        },
        assumeRolePolicy: JSON.stringify({
            Version: "2012-10-17",
            Statement: [{
                Effect: "Allow",
                Principal: {
                    Service: "pods.eks.amazonaws.com",
                },
                Action: [
                    "sts:AssumeRole",
                    "sts:TagSession",
                ],
            }],
        }),
    },
);
new aws.iam.RolePolicy(
    "clusterAutoscaling",
    {
        role: clusterAutoscaler_iamRole,
        name: "AllowRoleFunctions",
        policy: JSON.stringify({
            // refer https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/cloudprovider/aws/README.md
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
                    Resource: "*",  // keep '*' to allow autodiscovery
                },
                {
                    Effect: "Allow",
                    Action: [
                        "autoscaling:SetDesiredCapacity",
                        "autoscaling:TerminateInstanceInAutoScalingGroup",
                    ],
                    Resource: "*",  // FIXME: reduce to cluster-specific autoscaling groups
                },
            ],
        }),
    },
);
const clusterAutoscaling_PodIdentityAssociation = new aws.eks.PodIdentityAssociation(
    "clusterAutoscaling-role-to-k8sServiceAccount-cluster-autoscaler-aws",
    {
        clusterName: cluster.name,
        roleArn: clusterAutoscaler_iamRole.arn,
        serviceAccount: "cluster-autoscaler-aws",  // no need for it to exists beforehand
        namespace: "kube-system",
    },
);
pulumi
    .all([
        k8sProvider_output,
        awsRegionId_output,
        cluster.name,
        clusterAutoscaling_PodIdentityAssociation.serviceAccount,
    ])
    .apply(
        ([
            k8sProvider,
            regionId,
            clusterName,
            serviceAccountName,
        ]: [k8s.Provider, string, string, string]) => new k8s.helm.v4.Chart(
            "awsClusterAutoscaler",
            {
                namespace: "kube-system",
                name: "aws-cluster-autoscaler",
                chart: "cluster-autoscaler",
                repositoryOpts: {
                    repo: "https://kubernetes.github.io/autoscaler",
                },
                valueYamlFiles: [
                    new pulumi.asset.FileAsset("./chart-values/cluster-autoscaler.yml"),
                ],
                values: {
                    cloudProvider: "aws",
                    awsRegion: regionId,
                    autoDiscovery: {
                        clusterName: clusterName,
                    },
                    rbac: {
                        serviceAccount: {
                            name: serviceAccountName,
                        },
                    },
                    affinity: {
                        podAntiAffinity: {
                            preferredDuringSchedulingIgnoredDuringExecution: [{
                                weight: 100,
                                podAffinityTerm: {
                                    topologyKey: "kubernetes.io/hostname",
                                    labelSelector: {
                                        matchExpressions: [{
                                            key: "app.kubernetes.io/name",
                                            operator: "In",
                                            values: [
                                                "aws-cluster-autoscaler"
                                            ],
                                        }],
                                    },
                                },
                            }],
                        },
                    },
                },
            },
            { provider: k8sProvider },
        ),
    );

// -------

k8sProvider_output.apply(
    (k8sProvider: k8s.Provider) => new k8s.helm.v4.Chart(
        "metricsServer",
        {
            namespace: "kube-system",
            name: "metrics-server",
            chart: "metrics-server",
            repositoryOpts: {
                repo: "https://kubernetes-sigs.github.io/metrics-server",
            },
            valueYamlFiles: [
                new pulumi.asset.FileAsset("./chart-values/metrics-server.yml"),
            ],
            values: {
                containerPort: 10251,  // the same as Fargate to simplify observability
            },
        },
        { provider: k8sProvider },
    ),
);

/**
 * Step 4: install workloads.
 * -------------------------------------
 **/
