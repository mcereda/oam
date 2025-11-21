/**
 * Create Kubeconfig files to connect to existing EKS clusters
 * -----------------------------------------------------------------------------
 * Based off of <https://www.pulumi.com/ai/conversations/7b2695c1-4a32-4d69-9cba-68e28cc593ec>
 **/

import * as aws from "@pulumi/aws";
import * as k8s from "@pulumi/kubernetes";
import * as pulumi from "@pulumi/pulumi";
import * as yaml from "yaml";

const awsRegionId_output = aws.getRegionOutput().id;
const cluster_output = aws.eks.getClusterOutput({ name: "cluster" });
const clusterAdminRole_output = aws.iam.getRoleOutput({ name: "clusterAdmin" });

const kubeconfig_output = pulumi
    .all([
        cluster_output.arn,
        cluster_output.name,
        cluster_output.endpoint,
        cluster_output.certificateAuthorities[0],
        clusterAdminRole_output.arn,
        awsRegionId_output,
    ])
    .apply(
        ([
            clusterArn,
            clusterName,
            clusterEndpoint,
            clusterCertificateAuthority,
            clusterAdminRoleArn,
            awsRegionId,
        ]: [
            aws.ARN,
            string,
            string,
            aws.types.output.eks.ClusterCertificateAuthority,
            aws.ARN,
            string,
        ]) => yaml.stringify({
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
                            "--region", awsRegionId,
                            "eks",
                            "get-token",
                            "--cluster-name", clusterName,
                            "--role-arn", clusterAdminRoleArn,
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
    (content: string) => new k8s.Provider(
        "cluster",
        { kubeconfig: content },
    ),
);

// Use that provider to connect and do stuff.

// k8sProvider_output.apply(
//     (k8sProvider: k8s.Provider) => new k8s.helm.v4.Chart(
//         "metricsServer",
//         {
//             namespace: "kube-system",
//             name: "metrics-server",
//             chart: "metrics-server",
//             repositoryOpts: {
//                 repo: "https://kubernetes-sigs.github.io/metrics-server",
//             },
//             valueYamlFiles: [
//               new pulumi.asset.FileAsset("./chart-values/metrics-server.yaml"),
//             ],
//             values: {
//                 containerPort: 10251,  // the same as Fargate to simplify observability
//                 addonResizer: {
//                     enabled: true,
//                 },
//             },
//         },
//         { provider: k8sProvider },
//     ),
// );
