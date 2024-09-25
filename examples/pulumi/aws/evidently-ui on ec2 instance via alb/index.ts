import * as aws from "@pulumi/aws";
import * as cloudinit from "@pulumi/cloudinit";
import * as fs from "fs";
import * as pulumi from "@pulumi/pulumi";

/**
 * EvidentlyUi requirements - start
 * -------------------------------------
 */

const evidentlyUi_s3bucket = new aws.s3.Bucket(
    "evidentlyUi",
    { bucket: "evidentlyUi" },
);

const evidentlyUi_securityGroup_internal = new aws.ec2.SecurityGroup(
    "evidentlyUi",
    {
        name: "EvidentlyUiInternal",
        tags: { Name: "EvidentlyUiInternal" },
        ingress: [{
            description: "Allow connections between ALB and instance",
            self: true,
            protocol: "tcp",
            fromPort: 8000,
            toPort: 8000,
        }],
        egress: [{
            cidrBlocks: [ "0.0.0.0/0" ],
            protocol: "-1",
            fromPort: 0,
            toPort: 0,
        }],
    },
);

const evidentlyUi_securityGroup_external = new aws.ec2.SecurityGroup(
    "evidentlyUi-external",
    {
        name: "EvidentlyUiExternal",
        tags: { Name: "EvidentlyUiExternal" },
        ingress: [
            {
                description: "Allow connections to the ALB from outside via HTTP",
                cidrBlocks: [ "0.0.0.0/0" ],
                protocol: "tcp",
                fromPort: 80,
                toPort: 80,
            },
            {
                description: "Allow connections to the ALB from outside via HTTPS",
                cidrBlocks: [ "0.0.0.0/0" ],
                protocol: "tcp",
                fromPort: 443,
                toPort: 443,
            },
        ],
        egress: [{
            cidrBlocks: [ "0.0.0.0/0" ],
            protocol: "-1",
            fromPort: 0,
            toPort: 0,
        }],
    },
);

const evidentlyUi_publicSubnet_output = aws.ec2.getSubnetOutput({
    filters: [{
        name: "tag:Name",
        values: [ "Public Subnet in AZ B" ],
    }],
});

/**
 * -------------------------------------
 * EvidentlyUi requirements - end
 */

/**
 * EC2 Instance - start
 * -------------------------------------
 */

const evidentlyUi_instanceAmi_output = aws.ec2.getAmiOutput({
    owners: [ "amazon", ],
    nameRegex: "^al2023-ami-2023.*",
    filters: [
        {
            name: "architecture",
            values: [ "arm64" ],
        },
        {
            name: "state",
            values: [ "available" ],
        },
    ],
    mostRecent: true,
});

const evidentlyUi_instanceSubnet_output = aws.ec2.getSubnetOutput({
    filters: [{
        name: "tag:Name",
        values: [ "Private Subnet in AZ C" ],
    }],
});

const evidentlyUi_instanceKeyPair = new aws.ec2.KeyPair(
    "evidentlyUi",
    {
        keyName: "EvidentlyUi",
        publicKey: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA1CBr/1GqUX+/rUR00TK34+2sMWbRNkqbckGvYmtypu openpgp:0xE742BC48",
    },
);

const evidentlyUi_instanceRole = evidentlyUi_s3bucket.arn.apply(
    bucketArn => new aws.iam.Role(
        "evidentlyUi-instance",
        {
            name: "EvidentlyUiInstanceRole",
            assumeRolePolicy: JSON.stringify({
                Version: "2012-10-17",
                Statement: [{
                    Effect: "Allow",
                    Principal: { Service: "ec2.amazonaws.com" },
                    Action: "sts:AssumeRole",
                }],
            }),
            inlinePolicies: [{
                name: "AllowManagingOwnBucket",
                policy: JSON.stringify({
                    Version: "2012-10-17",
                    Statement: [{
                        Effect: "Allow",
                        Action: "s3:*",
                        Resource: [
                            `${bucketArn}`,
                            `${bucketArn}/*`,
                        ],
                    }],
                }),
            }],
        },
    ),
);

const evidentlyUi_instanceProfile = new aws.iam.InstanceProfile(
    "evidentlyUi-ec2Instance",
    {
        name: "EvidentlyUiInstanceProfile",
        role: evidentlyUi_instanceRole.name,
    },
);

const evidentlyUi_instanceUserData = new cloudinit.Config(
    "evidentlyUi-instance",
    {
        gzip: true,
        base64Encode: true,
        parts: [{
            contentType: "text/cloud-config",
            content: fs.readFileSync("cloud-config.evidently-ui.yml", "utf8"),
            filename: "cloud-config.evidently-ui.yml",
        }],
    },
);

const evidentlyUi_instance = new aws.ec2.Instance(
    "evidentlyUi",
    {
        ami: evidentlyUi_instanceAmi_output.id,
        iamInstanceProfile: evidentlyUi_instanceProfile.name,
        instanceType: "t4g.micro",
        keyName: evidentlyUi_instanceKeyPair.keyName!,
        rootBlockDevice: {
            volumeType: "gp3",
            volumeSize: 20,
            tags: {
                Description: "Instance root disk",
                Name: "EvidentlyUi-instanceRootDisk",
            },
        },
        subnetId: evidentlyUi_instanceSubnet_output.id,
        tags: {
            Name: "EvidentlyUi",
            ManagedBySsm: "true",
            ManagedByAnsible: "true",
        },
        userData: evidentlyUi_instanceUserData.rendered,
        userDataReplaceOnChange: true,
        vpcSecurityGroupIds: [ evidentlyUi_securityGroup_internal.id ],
    },
    {
        ignoreChanges: [
            "ami",  // avoid replacing just because a new version of the base image came out
        ],
    },
);

/**
 * -------------------------------------
 * EC2 Instance - end
 */

/**
 * Application Load Balancer - start
 * -------------------------------------
 */

const evidentlyUi_targetGroup = new aws.alb.TargetGroup(
    "evidentlyUi",
    {
        name: "EvidentlyUi",
        vpcId: evidentlyUi_instanceSubnet_output.vpcId,
        targetType: "instance",
        port: 8000,
        protocol: "HTTP",
        protocolVersion: "HTTP1",
    },
);
new aws.lb.TargetGroupAttachment(
    "evidentlyUi",
    {
        targetGroupArn: evidentlyUi_targetGroup.arn,
        targetId: evidentlyUi_instance.id,
    },
);

const evidentlyUi_applicationLoadBalancer = new aws.alb.LoadBalancer(
    "evidentlyUi",
    {
        name: "EvidentlyUi",
        ipAddressType: "ipv4",
        subnets: [
            evidentlyUi_publicSubnet_output.id,    // external
            evidentlyUi_instanceSubnet_output.id,  // internal
        ],
        securityGroups: [
            evidentlyUi_securityGroup_external.id,
            evidentlyUi_securityGroup_internal.id,
        ],
        accessLogs: { bucket: "" },
    },
);
new aws.alb.Listener(
    "evidentlyUi-http2https",
    {
        loadBalancerArn: evidentlyUi_applicationLoadBalancer.arn,
        port: 80,
        defaultActions: [{
            order: 1,
            redirect: {
                port: "443",
                protocol: "HTTPS",
                statusCode: "HTTP_301",
            },
            type: "redirect",
        }],
    },
);
new aws.alb.Listener(
    "evidentlyUi-https",
    {
        loadBalancerArn: evidentlyUi_applicationLoadBalancer.arn,
        port: 443,
        protocol: "HTTPS",
        certificateArn: "arn:aws:acm:eu-west-1:012345678901:certificate/01234567-abcd-8901-abcd-abcdef012345",
        defaultActions: [{
            order: 1,
            targetGroupArn: evidentlyUi_targetGroup.arn,
            type: "forward",
        }],
    },
);
new aws.route53.Record(
    "evidentlyUi",
    {
        aliases: [{
            evaluateTargetHealth: true,
            name: pulumi.interpolate`dualstack.${evidentlyUi_applicationLoadBalancer.dnsName}`,
            zoneId: "Z012345678ABCD",
        }],
        name: "evidently-ui.dev.company.com",
        type: "A",
        zoneId: "Z9ABCD12345678",
    },
);

/**
 * -------------------------------------
 * Application Load Balancer - end
 */
