import * as aws from "@pulumi/aws";

const vpc_output = aws.ec2.getVpcOutput({
    filters: [{
        name: "tag:Name",
        values: "Default",
    }],
});

const dnsZone_output = aws.route53.getZoneOutput({ name: "example.org." });

const ecsCluster_output = aws.ecs.getClusterOutput({ clusterName: "someCluster" });

const securityGroup = new aws.ec2.SecurityGroup(
    "loki",
    {
        vpcId: vpc_output.apply((vpc: aws.ec2.Vpc) => vpc.id),
        name: "Loki",
        description: "Manage access to and from Loki",
        tags: {
            Name: "Loki",
            Application: "Loki",
        },

        ingress: [
            {
                description: "HTTP server",
                cidrBlocks: [ "0.0.0.0/0" ],
                ipv6CidrBlocks: [ "::/0" ],
                protocol: "tcp",
                fromPort: 3100,
                toPort: 3100,
            },
            {
                description: "gRPC server",
                cidrBlocks: [ "0.0.0.0/0" ],
                ipv6CidrBlocks: [ "::/0" ],
                protocol: "tcp",
                fromPort: 9095,
                toPort: 9095,
            },
        ],
        egress: [{
            description: "Allow all",
            cidrBlocks: [ "0.0.0.0/0" ],
            ipv6CidrBlocks: [ "::/0" ],
            protocol: "-1",
            fromPort: 0,
            toPort: 0,
        }],
    },
);

const taskDefinition = new aws.ecs.TaskDefinition(
    "loki",
    {
        family: "Loki",
        tags: { Application: "Loki" },

        networkMode: "awsvpc",
        requiresCompatibilities: [ "FARGATE" ],
        cpu: "256",     // Fargate requirement
        memory: "512",  // Fargate requirement
        executionRoleArn: "arn:aws:iam::012345678901:role/ecsTaskExecutionRole",  // logging requirement
        containerDefinitions: JSON.stringify([{
            name: "loki",
            image: "grafana/loki:3.3.2",
            essential: true,
            environment: [],     // specified to avoid showing changes on every run
            volumesFrom: [],     // specified to avoid showing changes on every run
            mountPoints: [],     // specified to avoid showing changes on every run
            systemControls: [],  // specified to avoid showing changes on every run
            healthCheck: {
                command: [
                    "CMD-SHELL",
                    "wget -qO- localhost:3100/ready || exit 1",
                ],
                startPeriod: 15,
            },
            portMappings: [
                {
                    name: "http-server",
                    appProtocol: "http",
                    containerPort: 3100,
                },
                {
                    name: "grpc-server",
                    appProtocol: "grpc",
                    containerPort: 9095,
                },
            ],
            logConfiguration: {
                logDriver: "awslogs",
                options: {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/loki",
                    "awslogs-region": "eu-west-1",
                    "awslogs-stream-prefix": "ecs",
                },
            },
        }]),
    },
);

const privateSubnets_output = aws.ec2.getSubnetOutput({
    filters: [{
        name: "tag:Type",
        values: [ "Private" ],
    }],
});
const targetGroup_http = new aws.alb.TargetGroup(
    "loki-http",
    {
        vpcId: vpc_output.apply((vpc: aws.ec2.Vpc) => vpc.id),
        name: "loki-http",
        tags: { Application: "Loki" },

        targetType: "ip",
        ipAddressType: "ipv4",
        protocol: "HTTP",
        port: 3100,
        healthCheck: {
            path: "/ready",
        },
    },
);
const targetGroup_grpc = new aws.alb.TargetGroup(
    "loki-grpc",
    {
        vpcId: vpc_output.apply((vpc: aws.ec2.Vpc) => vpc.id),
        name: "loki-grpc",
        tags: { Application: "Loki" },

        targetType: "ip",
        ipAddressType: "ipv4",
        protocol: "HTTP",
        protocolVersion: "GRPC",
        port: 9095,
    },
);
const loadBalancer = new aws.alb.LoadBalancer(
    "loki",
    {
        name: "Loki",
        tags: { Application: "Loki" },

        internal: true,
        ipAddressType: "ipv4",
        subnets: privateSubnets_output.apply((subnets: aws.ec2.Subnet[]) => subnets.map(subnet => subnet.id)),
        securityGroups: [ securityGroup.id ],
        accessLogs: {
            bucket: "",
        },
    },
);
new aws.route53.Record(
    "loki",
    {
        zoneId: dnsZone_output.apply((zone: aws.route53.Zone) => zone.zoneId),
        name: "loki.example.org",
        type: "A",
        aliases: [{
            name: loadBalancer.dnsName,
            zoneId: loadBalancer.zoneId,
            evaluateTargetHealth: true,
        }],
    },
);
new aws.alb.Listener(
    "loki-http",
    {
        tags: { Application: "Loki" },
        loadBalancerArn: loadBalancer.arn,
        port: 3100,
        protocol: "HTTP",
        defaultActions: [{
            order: 1,
            targetGroupArn: targetGroup_http.arn,
            type: "forward",
        }],
    },
);
// new aws.alb.Listener(
//     FIXME: Listener protocol 'HTTP' is not supported with a target group with the protocol-version 'GRPC'
//     "loki-grpc",
//     {
//         tags: { Application: "Loki" },
//         loadBalancerArn: loadBalancer.arn,
//         port: 9095,
//         protocol: "HTTP",
//         defaultActions: [{
//             order: 1,
//             targetGroupArn: targetGroup_grpc.arn,
//             type: "forward",
//         }],
//     },
// );
new aws.ecs.Service(
    "loki",
    {
        name: "Loki",
        tags: { Application: "Loki" },

        cluster: ecsCluster_output.arn,
        taskDefinition: taskDefinition.arn,
        desiredCount: 1,
        launchType: "FARGATE",
        networkConfiguration: {
            subnets: privateSubnets_output.apply((subnets: aws.ec2.Subnet[]) => subnets.map(subnet => subnet.id)),
            securityGroups: [ securityGroup.id ],
        },
        loadBalancers: [
            {
                containerName: "loki",
                containerPort: 3100,
                targetGroupArn: targetGroup_http.arn,
            },
            // {
            //     containerName: "loki",
            //     containerPort: 9095,
            //     targetGroupArn: targetGroup_grpc.arn,
            // },
        ],
    },
);
