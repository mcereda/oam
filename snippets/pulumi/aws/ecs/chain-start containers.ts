import {
    getListenerOutput, GetListenerResult,
    getLoadBalancerOutput, GetLoadBalancerResult,
    ListenerRule,
    TargetGroup,
} from '@pulumi/aws/alb';
import { LogGroup } from '@pulumi/aws/cloudwatch';
import {
    getSecurityGroupOutput, GetSecurityGroupResult,
    getSubnetsOutput, GetSubnetsResult,
    getVpcOutput, GetVpcResult,
    SecurityGroup,
} from '@pulumi/aws/ec2';
import { getImageOutput, GetImageResult } from '@pulumi/aws/ecr';
import {
    getClusterOutput, GetClusterResult,
    Service,
    TaskDefinition,
} from '@pulumi/aws/ecs';
import { getRoleOutput, GetRoleResult } from '@pulumi/aws/iam';
import { Secret, SecretVersion } from '@pulumi/aws/secretsmanager';
import { SecurityGroupEgressRule, SecurityGroupIngressRule } from '@pulumi/aws/vpc';
import {
    Config as PulumiConfig,
    Input as PulumiInput,
    Output as PulumiOutput,
    interpolate as pulumiInterpolate,
    jsonStringify as pulumiJsonStringify,
} from '@pulumi/pulumi';

const pulumiConfig = new PulumiConfig();

const dbImage: string = pulumiConfig.get('dbImage')
    || '012345678901.dkr.ecr.eu-west-1.amazonaws.com/cache/dockerHub/library/postgres:16.8';
const dbPort: number = pulumiConfig.getNumber('dbPort') || 5432;
const dbName: string = pulumiConfig.get('dbName') || 'postgres';
const dbUser: string = pulumiConfig.get('dbUser') || 'postgres';
const dbPassword: string = pulumiConfig.requireSecret('dbPassword');

const vpc: PulumiOutput<GetVpcResult> = getVpcOutput({ default: true });
const subnets: PulumiOutput<GetSubnetsResult> = getSubnetsOutput({
    region: vpc.region,
    filters: [{
        name: 'tag:Name',
        values: [
            'private-a',
            'private-b',
            'private-c',
        ],
    }],
});

const ecsCluster: PulumiOutput<GetClusterResult> = getClusterOutput({
    region: vpc.region,
    clusterName: 'development',
});
const ecsExecutionRole: PulumiOutput<GetRoleResult> = getRoleOutput({ name: 'mainApp-dev-ecsExecutionRole' });
const ecsTaskRole:      PulumiOutput<GetRoleResult> = getRoleOutput({ name: 'mainApp-dev-ecsTaskRole' });

const vpn_securityGroup: PulumiOutput<GetSecurityGroupResult> = getSecurityGroupOutput({
    vpcId: vpc.id,
    name: 'vpn',
});

const loadBalancer: PulumiOutput<GetLoadBalancerResult> = getLoadBalancerOutput({
    region: vpc.region,
    name: 'mainApp-dev',
});
const listener: PulumiOutput<GetListenerResult> = getListenerOutput({
    loadBalancerArn: loadBalancer.arn,
    port: 443,
});

const mainApp_imageTag: string = 'latest';
const mainApp_image: PulumiOutput<GetImageResult> = getImageOutput({
    repositoryName: 'mainApp',
    imageTag: mainApp_imageTag,
});
const mainApp_imageReference: PulumiOutput<string> = mainApp_image.imageUri;

const commonTags: PulumiInput<{ [key: string]: PulumiInput<string> }> = {
    Team: 'Infrastructure',
    Owner: 'infrastructure@example.org',
    Application: 'MainApp',
    Component: 'Service',
    ManagedByPulumi: 'true',
    PulumiProject: 'mainApp/infra/dev',
};

const dbPassword_secret: Secret = new Secret(
    'dbPassword',
    {
        name: 'mainApp/dev/db/password',
        description: 'Password',
        tags: {
            Application: 'MainApp',
            Environment: 'Development',
            Component: 'Service',
        },
    },
    { protect: true },
);
new SecretVersion(
    'dbPassword',
    {
        secretId: dbPassword_secret.id,
        secretString: dbPassword,
        versionStages: [
            'INITIAL',
            'AWSCURRENT',
        ],
    },
    { parent: dbPassword_secret },
);

const logGroup: LogGroup = new LogGroup(
    'mainApp',
    {
        name: '/ecs/mainApp/dev',
        tags: {
            ...commonTags,
        },

        retentionInDays: 14,
    },
);

const containerDefinitions: unknown = [
    {
        name: 'db',

        essential: true,
        image: dbImage,
        environment: [
            // server config
            { name: 'POSTGRES_PORT', value: dbPort.toString() },
            { name: 'POSTGRES_DB', value: dbName },
            { name: 'POSTGRES_USER', value: dbUser },
            { name: 'POSTGRES_PASSWORD', value: dbPassword },
            // needed by the health check
            { name: 'PGPORT', value: dbPort.toString() },
        ],
        portMappings: [{
            protocol: 'tcp',
            appProtocol: 'http',
            containerPort: dbPort,
            hostPort: dbPort,
        }],
        healthCheck: {
            command: [ 'CMD-SHELL', "pg_isready -h 'localhost' || exit 1" ],
            interval: 30,
            timeout: 5,
            retries: 2,
            startPeriod: 15,
        },
        logConfiguration: {
            logDriver: 'awslogs',
            options: {
                'awslogs-region': 'eu-west-1',
                'awslogs-group': logGroup.name,
                'awslogs-stream-prefix': 'db',
            },
        },
    },
    {
        name: 'db-init',

        essential: false,  // cannot be essential if others need to depend on it being in the COMPLETE state
        dependsOn: [
            {
                containerName: 'db',
                condition: 'HEALTHY',
            },
        ],
        image: mainApp_imageReference,
        environment: [
            {
                name: 'PGHOST',
                value: 'localhost',  // ecs does *not* resolve container names to ip addresses like docker and k8s do
            },
            { name: 'PGPORT', value: dbPort.toString() },
            { name: 'PGDATABASE', value: dbName },
            { name: 'PGUSER', value: dbUser },
        ],
        secrets: [
            { name: 'PGPASSWORD', valueFrom: dbPassword_secret.arn },
        ],
        workingDirectory: '/opt/src',
        command: [ 'alembic', 'upgrade', 'head' ],
        logConfiguration: {
            logDriver: 'awslogs',
            options: {
                'awslogs-region': 'eu-west-1',
                'awslogs-group': logGroup.name,
                'awslogs-stream-prefix': 'db',
            },
        },
    },
    {
        name: 'mainApp',

        essential: true,
        dependsOn: [{
            containerName: 'db-init',
            condition: 'COMPLETE',
        }],
        image: mainApp_imageReference,
        environment: [
            {
                name: 'PGHOST',
                value: 'localhost',  // ecs does *not* resolve container names to ip addresses like docker and k8s do
            },
            { name: 'PGPORT', value: dbPort.toString() },
            { name: 'PGDATABASE', value: dbName },
            { name: 'PGUSER', value: dbUser },
        ],
        secrets: [
            { name: 'PGPASSWORD', valueFrom: dbPassword_secret.arn },
        ],
        healthCheck: {
            command: [ 'CMD-SHELL', 'curl -f http://localhost:8080/ || exit 1' ],
            interval: 30,
            timeout: 5,
            retries: 2,
            startPeriod: 15,
        },
        portMappings: [{
            protocol: 'tcp',
            appProtocol: 'http',
            containerPort: 8080,
            hostPort: 8080,
        }],
        logConfiguration: {
            logDriver: 'awslogs',
            options: {
                'awslogs-region': 'eu-west-1',
                'awslogs-group': logGroup.name,
                'awslogs-stream-prefix': 'mainApp',
            },
        },
    },
];
const taskDefinition: TaskDefinition = new TaskDefinition(
    'mainApp',
    {
        family: 'mainApp',
        tags: {
            ...commonTags,
        },

        executionRoleArn: ecsExecutionRole.arn,
        taskRoleArn: ecsTaskRole.arn,
        containerDefinitions: pulumiJsonStringify(containerDefinitions),
        cpu: '2048',
        memory: '4096',
        networkMode: 'awsvpc',
        requiresCompatibilities: [
            'FARGATE',
        ],
        runtimePlatform: {
            cpuArchitecture: 'X86_64',
            operatingSystemFamily: 'LINUX',
        },
    },
);

const securityGroup: SecurityGroup = new SecurityGroup(
    'mainApp',
    {
        name: 'mainApp-dev',
        description: 'Controls the network perimeter for MainApp in development',
        tags: {
            ...commonTags,
            Name: 'MainApp Dev',
        },

        vpcId: vpc.id,
    },
);
new SecurityGroupEgressRule(
    'mainApp-allowAll:ipv4',
    {
        securityGroupId: securityGroup.id,
        description: 'All IPv4 connections',
        tags: {
            Name: 'All IPv4',
        },

        cidrIpv4: '0.0.0.0/0',
        ipProtocol: '-1',
    },
    { parent: securityGroup },
);
new SecurityGroupEgressRule(
    'mainApp-allowAll:ipv6',
    {
        securityGroupId: securityGroup.id,
        description: 'All IPv6 connections',
        tags: {
            Name: 'All IPv6',
        },

        cidrIpv6: '::/0',
        ipProtocol: '-1',
    },
    { parent: securityGroup },
);
new SecurityGroupIngressRule(
    'mainApp-internalTraffic',
    {
        securityGroupId: securityGroup.id,
        description: 'Traffic between members of this Security Group',
        tags: {
            Name: 'Internal traffic',
        },

        referencedSecurityGroupId: securityGroup.id,
        ipProtocol: '-1',
    },
    { parent: securityGroup },
);
new SecurityGroupIngressRule(
    'mainApp-vpn',
    {
        securityGroupId: securityGroup.id,
        description: 'Traffic from the VPN',
        tags: {
            Name: 'VPN',
        },

        referencedSecurityGroupId: vpn_securityGroup.id,
        ipProtocol: '-1',
    },
    { parent: securityGroup },
);

const targetGroup: TargetGroup = new TargetGroup(
    'mainApp',
    {
        name: 'MainApp',
        tags: {
            ...commonTags,
        },

        vpcId: vpc.id,
        ipAddressType: 'ipv4',
        targetType: 'ip',
        protocol: 'HTTP',
        protocolVersion: 'HTTP2',
        port: 80,
        healthCheck: {
            healthyThreshold: 5,
            matcher: '200',
            path: '/',
            timeout: 5,
            unhealthyThreshold: 2,
        },
        loadBalancingAlgorithmType: 'round_robin',
        loadBalancingCrossZoneEnabled: 'use_load_balancer_configuration',
        stickiness: {
            enabled: true,
            type: 'lb_cookie',
        },
        deregistrationDelay: 30,
    },
);
new ListenerRule(
    'mainApp',
    {
        tags: {
            ...commonTags,
            Name: 'MainApp',
        },

        listenerArn: listener.arn,
        actions: [{
            type: 'forward',
            targetGroupArn: targetGroup.arn,
        }],
        conditions: [{
            hostHeader: {
                values: [
                    'main-app.dev.example.org',
                ],
            },
        }],
    },
);

new Service(
    'mainApp',
    {
        name: 'mainApp',
        tags: {
            ...commonTags,
        },

        cluster: ecsCluster.arn,
        taskDefinition: pulumiInterpolate`${taskDefinition.family}:${taskDefinition.revision}`,
        capacityProviderStrategies: [{
            capacityProvider: 'FARGATE_SPOT',
            weight: 1,
        }],
        platformVersion: 'LATEST',
        desiredCount: 1,
        healthCheckGracePeriodSeconds: 5,
        loadBalancers: [{
            containerName: 'mainApp',
            containerPort: 9000,
            targetGroupArn: targetGroup.arn,
        }],
        networkConfiguration: {
            subnets: subnets.ids,
            securityGroups: [
                securityGroup.id,
            ],
        },
        forceNewDeployment: true,
        deploymentCircuitBreaker: {
            enable: true,
            rollback: true,
        },
        enableEcsManagedTags: true,
        propagateTags: 'SERVICE',
        enableExecuteCommand: true,
        waitForSteadyState: true,
    },
);
