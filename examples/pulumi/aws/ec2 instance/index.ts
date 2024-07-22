import * as aws from "@pulumi/aws";
import * as cloudinit from "@pulumi/cloudinit";
import * as yaml from "yaml";

const ami = aws.ec2.getAmiOutput({
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
const keyPair = aws.ec2.getKeyPairOutput({ keyName: "somebody-ec2Instances" });
const subnet = aws.ec2.getSubnetOutput({
    filters: [{
        name: "tag:Name",
        values: [ "Private C" ],
    }],
});

const securityGroup = new aws.ec2.SecurityGroup(
    "ec2-instance-example",
    {
        name: "Ec2InstanceExample",
        description: "Regulate communications to and from the EC2 Instance",
        tags: {
            Name: "EC2 Instance Example",
        },
    },
);
const role = new aws.iam.Role(
    "ec2-instance-example",
    {
        name: "Ec2InstanceExample",
        assumeRolePolicy: JSON.stringify({
            Version: "2012-10-17",
            Statement: [{
                Effect: "Allow",
                Action: "sts:AssumeRole",
                Principal: {
                    Service: "ec2.amazonaws.com",
                },
            }],
        }),
        managedPolicyArns: [ "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" ],
    },
);
const instanceProfile = new aws.iam.InstanceProfile(
    "ec2-instance-example",
    {
        name: "Ec2InstanceExample",
        role: role.name,
    },
);
const userData = new cloudinit.Config(
    "ec2-instance-example",
    {
        gzip: true,
        base64Encode: true,
        parts: [
            {
                // only useful on minimal al2023 base images or other images with no aws-ssm
                contentType: "text/cloud-config",
                content: yaml.stringify({
                    package_upgrade: false,
                    packages: [ "amazon-ssm-agent" ],
                    runcmd: [
                        "systemctl daemon-reload",
                        "systemctl enable --now 'amazon-ssm-agent.service'",
                    ]
                }),
                filename: "cloud-config.managed-by.ssm.yml",
            },
            {
                contentType: "text/cloud-config",
                content: yaml.stringify({
                    package_upgrade: false,
                    packages: [ "python" ],
                }),
                filename: "cloud-config.managed-by.ansible.yml",
                mergeType: "dict(recurse_array,no_replace)+list(append)",
            },
        ],
    },
);
new aws.ec2.Instance(
    "ec2-instance-example",
    {
        ami: ami.apply(ami => ami.id),
        iamInstanceProfile: instanceProfile.name,
        instanceType: "t4g.small",
        keyName: keyPair.apply(keyPair => keyPair.keyName!),
        rootBlockDevice: {
            volumeType: "gp3",
            volumeSize: 20,
            tags: {
                Description: "Instance root disk",
                Name: "EC2 Instance Example",
            },
        },
        subnetId: subnet.apply(subnet => subnet.id),
        tags: {
            Name: "EC2 Instance Example",
            ManagedBySsm: "true",
            ManagedByAnsible: "true",
        },
        userData: userData.rendered,
        vpcSecurityGroupIds: [ securityGroup.id ],
    },
    {
        ignoreChanges: [
            // avoid being replaced just because a new version of the base image came out
            "ami",
        ],
    }
);
