import * as pulumi from '@pulumi/pulumi';
import * as aws from '@pulumi/aws';

const dnsZone: pulumi.Output<aws.route53.GetZoneResult> = aws.route53.getZoneOutput({ name: 'example.com.' });
const ecsCluster: pulumi.Output<aws.ecs.GetClusterResult> = aws.ecs.getClusterOutput({ clusterName: 'development' });
const ecsTaskExecutionRole: pulumi.Output<aws.iam.GetRoleResult> = aws.iam.getRoleOutput({ name: 'DefaultEcsTaskExecutionRole' });
const privateSubnets: pulumi.Output<aws.ec2.GetSubnetsResult> = aws.ec2.getSubnetsOutput({
    filters: [{
        name: 'tag:Name',
        values: [
            'private-a',
            'private-b',
            'private-c',
        ],
    }],
});
const vpc: pulumi.Output<aws.ec2.GetVpcResult> = aws.ec2.getVpcOutput({ default: true });

// FIXME: check before use

const securityGroup: aws.ec2.SecurityGroup = new aws.ec2.SecurityGroup(
    'mimir',
    {
        name: 'mimir',
        description: 'Manage access to and from the Mimir ECS service',
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Networking',
            Name: 'Mimir',
        },

        vpcId: vpc.id,
    },
);
new aws.vpc.SecurityGroupIngressRule(
    'mimir-internalTraffic',
    {
        securityGroupId: securityGroup.id,
        description: 'Traffic within the Security Group',
        tags: {
            Name: 'Intra-SG traffic',
        },

        referencedSecurityGroupId: securityGroup.id,
        ipProtocol: '-1',
    },
    {
        deleteBeforeReplace: true,
        parent: securityGroup,
    },
);
new aws.vpc.SecurityGroupIngressRule(
    'mimir-VPC:IPv4-httpServer',
    {
        description: 'Access the Mimir HTTP server from resources in the VPC via IPv4',
        tags: {
            Name: 'VPC IPv4 to HTTP server',
        },

        securityGroupId: securityGroup.id,
        cidrIpv4: vpc.cidrBlock,
        ipProtocol: 'tcp',
        fromPort: 8080,
        toPort: 8080,
    },
    {
        deleteBeforeReplace: true,
        parent: securityGroup,
    },
);
new aws.vpc.SecurityGroupIngressRule(
    'mimir-VPC:IPv6-httpServer',
    {
        description: 'Access the Mimir HTTP server from resources in the VPC via IPv6',
        tags: {
            Name: 'VPC IPv6 to HTTP server',
        },

        securityGroupId: securityGroup.id,
        cidrIpv6: vpc.ipv6CidrBlock,
        ipProtocol: 'tcp',
        fromPort: 8080,
        toPort: 8080,
    },
    {
        deleteBeforeReplace: true,
        parent: securityGroup,
    },
);
new aws.vpc.SecurityGroupIngressRule(
    'mimir-VPC:IPv4-gRPCServer',
    {
        description: 'Access the Mimir gRPC server from resources in the VPC via IPv4',
        tags: {
            Name: 'VPC IPv4 to gRPC server',
        },

        securityGroupId: securityGroup.id,
        cidrIpv4: vpc.cidrBlock,
        ipProtocol: 'tcp',
        fromPort: 9095,
        toPort: 9095,
    },
    {
        deleteBeforeReplace: true,
        parent: securityGroup,
    },
);
new aws.vpc.SecurityGroupIngressRule(
    'mimir-VPC:IPv6-gRPCServer',
    {
        description: 'Access the Mimir gRPC server from resources in the VPC via IPv6',
        tags: {
            Name: 'CurrentEverythingVpc IPv6 to gRPC server',
        },

        securityGroupId: securityGroup.id,
        cidrIpv6: vpc.ipv6CidrBlock,
        ipProtocol: 'tcp',
        fromPort: 9095,
        toPort: 9095,
    },
    {
        deleteBeforeReplace: true,
        parent: securityGroup,
    },
);
new aws.vpc.SecurityGroupEgressRule(
    'mimir-allowAllIPv4',
    {
        description: 'Connect everywhere from Mimir on IPv4',
        tags: {
            Name: 'All IPv4',
        },

        securityGroupId: securityGroup.id,
        cidrIpv4: '0.0.0.0/0',
        ipProtocol: '-1',
    },
    {
        deleteBeforeReplace: true,
        parent: securityGroup,
    },
);
new aws.vpc.SecurityGroupEgressRule(
    'mimir-allowAllIPv6',
    {
        description: 'Connect everywhere from Mimir on IPv6',
        tags: {
            Name: 'All IPv6',
        },

        securityGroupId: securityGroup.id,
        cidrIpv6: '::/0',
        ipProtocol: '-1',
    },
    {
        deleteBeforeReplace: true,
        parent: securityGroup,
    },
);

const bucket: aws.s3.BucketV2 = new aws.s3.BucketV2(
    'mimir',
    {
        bucket: 'mimir',
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Storage',
        },
    },
);

const ecsTaskRole: aws.iam.Role = new aws.iam.Role(
    'mimir-ecsTask',
    {
        name: 'Mimir-ECSTask',
        description: 'Allow Mimir ECS tasks to access the resources they need',
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Server',
        },

        assumeRolePolicy: JSON.stringify({
            Version: '2012-10-17',
            Statement: [{
                Effect: 'Allow',
                Principal: {
                    Service: 'ecs-tasks.amazonaws.com',
                },
                Action: 'sts:AssumeRole',
            }],
        }),
    },
);
new aws.iam.RolePolicy(
    'mimir-ecsTask-allowRoleFunctions',
    {
        role: ecsTaskRole,
        name: 'AllowRoleFunctions',

        policy: pulumi.jsonStringify({
            Version: '2012-10-17',
            Statement: [{
                Sid: 'AllowUsingS3BucketsForData',
                Effect: 'Allow',
                Action: [
                    's3:ListBucket',
                    's3:PutObject',
                    's3:GetObject',
                    's3:DeleteObject',
                ],
                Resource: [
                    pulumi.interpolate `${bucket.arn}`,
                    pulumi.interpolate `${bucket.arn}/*`,
                ],
            }],
        }),
    },
);

const cloudMap_namespace = new aws.servicediscovery.PrivateDnsNamespace(
    'mimir',
    {
        name: 'mimir.dev.ecs.local',
        description: 'Mimir Development',
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Networking',
        },

        vpc: vpc.id,
    },
);
const cloudMap_service = new aws.servicediscovery.Service(
    'mimir-memberlist',
    {
        name: 'memberlist',
        description: 'Gossip ring for ingesters in Mimir',
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Networking',
        },

        namespaceId: cloudMap_namespace.id,
        dnsConfig: {
            namespaceId: cloudMap_namespace.id,
            dnsRecords: [{
                type: 'A',
                ttl: 10,
            }],
            routingPolicy: 'MULTIVALUE',
        },
    },
);

const logGroup: aws.cloudwatch.LogGroup = new aws.cloudwatch.LogGroup(
    'mimir',
    {
        name: '/ecs/dev/mimir',
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Server',
        },

        retentionInDays: 7,
    },
);

const taskDefinition: aws.ecs.TaskDefinition = new aws.ecs.TaskDefinition(
    'mimir',
    {
        family: 'mimir',
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Server',
        },

        networkMode: 'awsvpc',
        requiresCompatibilities: [ 'FARGATE' ],
        cpu: '512',      // Fargate requirement. See <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-tasks-services.html#fargate-tasks-size>.
        memory: '1024',  // Fargate requirement. See <https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-tasks-services.html#fargate-tasks-size>.
        executionRoleArn: ecsTaskExecutionRole.arn,  // logging requirement
        taskRoleArn: ecsTaskRole.arn,
        containerDefinitions: pulumi.jsonStringify([
            {
                name: 'mimir',
                image: '012345678901.dkr.ecr.eu-west-1.amazonaws.com/cache/docker-hub/grafana/mimir:2.15.2',
                essential: true,
                command: [
                    '-auth.multitenancy-enabled=false',
                    pulumi.interpolate `-memberlist.join=dns+${cloudMap_service.name}.${cloudMap_namespace.name}:7946`,
                    '-common.storage.backend=s3',
                    '-common.storage.s3.endpoint=s3.eu-west-1.amazonaws.com',  // required
                    pulumi.interpolate `-common.storage.s3.bucket-name=${bucket.bucket}`,
                    '-alertmanager-storage.storage-prefix=alertmanager',
                    '-blocks-storage.storage-prefix=blocks',
                    '-ruler-storage.storage-prefix=ruler',
                    '-ingester.max-global-series-per-user=300000',
                    '-ingester.out-of-order-time-window=5m',
                    '-ingester.ring.replication-factor=1',  // required when using less than 3 replicas
                ],
                // healthCheck: {
                //     // FIXME: the image uses `blobs` as base, which has no binaries but `mimir`
                //     // FIXME: mimir -target='continuous-test' -tests.write-endpoint='http://localhost:8080' -tests.read-endpoint='http://localhost:8080' -tests.smoke-test -server.http-listen-port='18080' -server.grpc-listen-port='19095' ??
                //     command: [
                //         'CMD-SHELL',
                //         'wget -qO- localhost:8080/ready || exit 1',
                //     ],
                //     startPeriod: 60,  // it takes a while
                //     retries: 10,
                // },
                portMappings: [
                    {
                        name: 'memberlist',
                        protocol: 'tcp',
                        appProtocol: 'http',
                        containerPort: 7946,
                        hostPort: 7946,
                    },
                    {
                        name: 'api',
                        protocol: 'tcp',
                        appProtocol: 'http',
                        containerPort: 8080,
                        hostPort: 8080,
                    },
                    {
                        name: 'grpc',
                        protocol: 'tcp',
                        appProtocol: 'http',
                        containerPort: 9095,
                        hostPort: 9095,
                    },
                ],
                logConfiguration: {
                    logDriver: 'awslogs',
                    options: {
                        'awslogs-group': logGroup.name,
                        'awslogs-region': 'eu-west-1',
                        'awslogs-stream-prefix': 'ecs/dev',
                    },
                },

                // explicitly specified to avoid showing changes on every run
                environment: [],
                mountPoints: [],
                systemControls: [],
                volumesFrom: [],
            },
        ]),
    },
);

const alb_targetGroup_http = new aws.alb.TargetGroup(
    'mimir-http',
    {
        name: 'mimir-http',
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Networking',
        },

        vpcId: vpc.id,
        targetType: 'ip',
        ipAddressType: 'ipv4',
        protocol: 'HTTP',
        port: 8080,
        healthCheck: {
            path: '/ready',
        },
    },
);
const alb_targetGroup_grpc = new aws.alb.TargetGroup(
    'mimir-grpc',
    {
        name: 'mimir-grpc',
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Networking',
        },

        vpcId: vpc.id,
        targetType: 'ip',
        ipAddressType: 'ipv4',
        protocol: 'HTTP',  // FIXME
        port: 9095,
        // healthCheck: {
        //     // FIXME
        //     path: '/ready',
        // },
    },
);
const alb = new aws.alb.LoadBalancer(
    'mimir',
    {
        name: 'mimir',
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Networking',
        },

        internal: true,
        ipAddressType: 'ipv4',
        subnets: privateSubnets.ids,
        securityGroups: [ securityGroup.id ],
        accessLogs: {
            bucket: bucket.bucket,
        },
    },
);
new aws.route53.Record(
    'mimir',
    {
        zoneId: dnsZone.id,
        name: pulumi.interpolate `mimir.dev.${dnsZone.name}`,
        type: 'A',
        aliases: [{
            name: alb.dnsName,
            zoneId: alb.zoneId,
            evaluateTargetHealth: true,
        }],
    },
);
new aws.alb.Listener(
    'mimir-http',
    {
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Networking',
        },

        loadBalancerArn: alb.arn,
        port: 8080,
        protocol: 'HTTP',
        defaultActions: [{
            order: 1,
            targetGroupArn: alb_targetGroup_http.arn,
            type: 'forward',
        }],
    },
);
new aws.alb.Listener(
    'mimir-grpc',
    {
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Networking',
        },
        loadBalancerArn: alb.arn,
        port: 9095,
        protocol: 'HTTP',  // FIXME?
        defaultActions: [{
            order: 1,
            targetGroupArn: alb_targetGroup_grpc.arn,
            type: 'forward',
        }],
    },
);

new aws.ecs.Service(
    'mimir',
    {
        name: 'mimir',
        tags: {
            Environment: 'Development',
            Application: 'Mimir',
            Component: 'Server',
        },

        cluster: ecsCluster.arn,
        taskDefinition: taskDefinition.arn,
        desiredCount: 1,  // requires mimir to start with the '-ingester.ring.replication-factor=1' option
        launchType: 'FARGATE',
        networkConfiguration: {
            subnets: privateSubnets.ids,
            securityGroups: [ securityGroup.id ],
        },
        loadBalancers: [
            {
                containerName: 'mimir',
                containerPort: 8080,
                targetGroupArn: alb_targetGroup_http.arn,
            },
            {
                containerName: 'mimir',
                containerPort: 9095,
                targetGroupArn: alb_targetGroup_grpc.arn,
            },
        ],
        // enableExecuteCommand: true,  // FIXME: the image uses `blobs` as base, which has no binaries but `mimir`
        serviceRegistries: {
            registryArn: cloudMap_service.arn,
        },
    },
    { deleteBeforeReplace: true },
);
