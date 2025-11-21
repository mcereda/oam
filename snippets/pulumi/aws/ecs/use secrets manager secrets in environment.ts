import {
    Output as PulumiOutput,
    interpolate as pulumiInterpolate, jsonStringify as pulumiJsonStringify,
} from "@pulumi/pulumi";
import { Secret, SecretPolicy, SecretVersion } from "@pulumi/aws/secretsmanager";
import {
    GetRoleResult,
    getRoleOutput,
} from "@pulumi/aws/iam";
import {
    GetClusterResult, Service, TaskDefinition,
    getClusterOutput,
} from "@pulumi/aws/ecs";
import {
    GetSecurityGroupResult, GetSubnetResult,
    getSecurityGroupOutput, getSubnetOutput,
} from "@pulumi/aws/ec2";

const executionRole: PulumiOutput<GetRoleResult> = getRoleOutput({ name: "ecsExecutionRole" });

const composite_secret: Secret = new Secret(
    "smSecretsInEnv-composite",
    {
        name: "composite-secret",
        description: "Some value-only secret",
        tags: {},
    },
);
new SecretVersion(
    "smSecretsInEnv-composite",
    {
        secretId: composite_secret.id,
        secretString: pulumiJsonStringify({
            someField: "someValue",
        }),
        versionStages: [
            "AWSCURRENT",
        ],
    },
    { parent: composite_secret },
);
new SecretPolicy(
    "smSecretsInEnv-composite",
    {
        secretArn: composite_secret.arn,
        policy: pulumiJsonStringify({
            Version: "2012-10-17",
            Statement: [
                {
                    Effect: "Allow",
                    Principal: {
                        AWS: executionRole.arn,
                    },
                    Action: "secretsmanager:GetSecretValue",
                    Resource: composite_secret.arn,
                },
            ],
        }),
    },
    { parent: composite_secret },
);

const valueOnly_secret: Secret = new Secret(
    "smSecretsInEnv-valueOnly",
    {
        name: "valueOnly-secret",
        description: "Some value-only secret",
        tags: {},
    },
);
new SecretVersion(
    "smSecretsInEnv-valueOnly",
    {
        secretId: valueOnly_secret.id,
        secretString: "value-only secret",
        versionStages: [
            "AWSCURRENT",
        ],
    },
    { parent: valueOnly_secret },
);
new SecretPolicy(
    "smSecretsInEnv-valueOnly",
    {
        secretArn: valueOnly_secret.arn,
        policy: pulumiJsonStringify({
            Version: "2012-10-17",
            Statement: [
                {
                    Effect: "Allow",
                    Principal: {
                        AWS: executionRole.arn,
                    },
                    Action: "secretsmanager:GetSecretValue",
                    Resource: valueOnly_secret.arn,
                },
            ],
        }),
    },
    { parent: valueOnly_secret },
);

const containerDefinitions = [
    {
        name: "echo-server",
        image: "mendhak/http-https-echo:38@sha256:c73e039e883944a38e37eaba829eb9a67641cd03eff868827683951feceef96e",
        essential: true,

        environment: [
            {
                name: "WHATEVER",
                value: "whatever",
            },
        ],
        secrets: [
            // loaded as environment variables, but their value is taken from Secrets Manager
            {
                name: "VALUE_ONLY_SECRET",
                valueFrom: valueOnly_secret.arn,
            },
            {
                // requires specifying the field name, prefixed by ':' and followed by '::'
                name: "COMPOSITE_SECRET",
                valueFrom: pulumiInterpolate`${composite_secret.arn}:someField::`,
            },
        ],

        healthCheck: {
            command: [
                "CMD-SHELL",
                `nc -vz -w1 localhost 8080 || nc -vz -w1 localhost 8443`,
            ],
            interval: 6,
            retries: 3,
            startPeriod: 3,
            timeout: 5,
        },
        portMappings: [
            {
                name: "http",
                protocol: "tcp",
                appProtocol: "http",
                containerPort: 8080,
                hostPort: 8080,
            },
            {
                name: "https",
                protocol: "tcp",
                appProtocol: "http",
                containerPort: 8443,
                hostPort: 8443,
            },
        ],
        mountPoints: [],
        systemControls: [],
        volumesFrom: [],
    },
];
const taskDefinition = new TaskDefinition(
    "smSecretsInEnv",
    {
        family: "SmSecretsInEnv",
        tags: {},

        containerDefinitions: pulumiJsonStringify(containerDefinitions),
        cpu: "256",
        memory: "512",
        executionRoleArn: executionRole.arn,
        networkMode: "awsvpc",
        requiresCompatibilities: [
            "FARGATE",
        ],
        runtimePlatform: {
            cpuArchitecture: "X86_64",
            operatingSystemFamily: "LINUX",
        },
    },
);

const cluster: PulumiOutput<GetClusterResult> = getClusterOutput({ clusterName: "dev" });
const securityGroup: PulumiOutput<GetSecurityGroupResult> = getSecurityGroupOutput({
    vpcId: "vpc-01234567",
    name: "default",
});
const subnet: PulumiOutput<GetSubnetResult> = getSubnetOutput({
    availabilityZone: "eu-west-1a",
    state: "available",
    filters: [{
        name: "tag:Name",
        values: [
            "priv-*",
        ],
    }],
});
new Service(
    "smSecretsInEnv",
    {
        name: "SmSecretsInEnv",
        cluster: cluster.arn,
        taskDefinition: taskDefinition.arn,
        tags: {},

        desiredCount: 1,
        launchType: "FARGATE",
        networkConfiguration: {
            subnets: [
                subnet.id,
            ],
            securityGroups: [
                securityGroup.id,
            ],
        },
    },
);
