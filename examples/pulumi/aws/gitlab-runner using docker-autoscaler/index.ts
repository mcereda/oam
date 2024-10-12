/**
 * Gitlab Runner Autoscaler using docker-autoscaler
 * -------------------------------------
 * This implementation uses a single EC2 instance that executes a gitlab runner leveraging the
 * 'docker-autoscaler' executor and acting as runner manager.
 * Both the manager and runners must have the Docker Engine installed.
 * The manager connects to the runners through the instance's default user, but can be set otherwise.
 * Runners must be set up so that the user the manager connects with can access the Docker Engine socket (i.e. adding)
 * it to the 'docker' group).
 * Runners are created and deleted by means of an AutoScaling Group that the manager controls.
 * Container images are pulled by the manager and sent to the runners through Docker pipes.
 *
 * Requirements:
 *   - An EC2 instance with Docker Engine to act as manager.
 *   - A Launch Template:
 *     - referencing an AMI equipped with Docker Engine for the runners to use, or
 *     - using any AMI but providing userData so that the Docker Engine is installed and configured "properly".
 *   - An AutoScaling Group with Minimum and Desired capacity set to 0.
 *   - Permissions to discover and scale the ASG (manager).
 *   - ECR authentication (manager).
 *   - ECR read only access to pull images from used repositories (manager).
 *
 * Pulumi resources info:
 *   - https://www.pulumi.com/registry/packages/aws/api-docs/ec2/securitygroup/
 *   - https://www.pulumi.com/registry/packages/aws/api-docs/vpc/securitygroupingressrule/
 *   - https://www.pulumi.com/registry/packages/aws/api-docs/vpc/securitygroupegressrule/
 *   - https://www.pulumi.com/registry/packages/aws/api-docs/autoscaling/group/
 *   - https://www.pulumi.com/registry/packages/aws/api-docs/ec2/launchtemplate/
 *   - https://www.pulumi.com/registry/packages/aws/api-docs/ec2/instance/
 **/

import * as aws from "@pulumi/aws";
import * as cloudinit from "@pulumi/cloudinit";
import * as pulumi from "@pulumi/pulumi";
import * as yaml from "yaml";

const awsRegion_output = aws.getRegionOutput();
const callerIdentity_output = aws.getCallerIdentity();

const config = new pulumi.Config();
const gitlab_url = config.require("gitlab-url");
const token = config.requireSecret("gitlab-runner-token");

const ami_amazonLinux_arm64_latest = aws.ec2.getAmiOutput({
    owners: [ "amazon" ],
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
const ami_amazonLinux_x86_64_latest = aws.ec2.getAmiOutput({
    owners: [ "amazon" ],
    nameRegex: "^al2023-ami-2023.*",
    filters: [
        {
            name: "architecture",
            values: [ "x86_64" ],
        },
        {
            name: "state",
            values: [ "available" ],
        },
    ],
    mostRecent: true,
});

const subnet_ids = aws.ec2.getSubnetsOutput({
    filters: [{
        name: "tag:Name",
        values: [
            // "private_a",
            // "private_b",
            // "private_c",
            "private-eu-west-1a",
            "private-eu-west-1b",
            "private-eu-west-1c",
        ],
    }],
}).apply(subnets => subnets.ids);

// manager's security group - start
const gitlab_runner_autoscalingManager_securityGroup = new aws.ec2.SecurityGroup(
    "gitlab-runner-autoscalingManager",
    {
        name: "Gitlab Runner autoscaling manager",
        description: "Security perimeter for the Gitlab Runner autoscaling manager",
        tags: {
            Name: "Gitlab Runner autoscaling manager",
        },
    },
);
new aws.vpc.SecurityGroupIngressRule(
    "gitlab-runner-autoscalingManager-fullAccess",
    {
        securityGroupId: gitlab_runner_autoscalingManager_securityGroup.id,
        description: "Allow all",
        cidrIpv4: "0.0.0.0/0",
        ipProtocol: "-1",
    },
);
new aws.vpc.SecurityGroupEgressRule(
    "gitlab-runner-autoscalingManager-fullAccess",
    {
        securityGroupId: gitlab_runner_autoscalingManager_securityGroup.id,
        description: "Allow all",
        cidrIpv4: "0.0.0.0/0",
        ipProtocol: "-1",
    },
);
// manager's security group - end

// runners' security group - start
const gitlab_runners_securityGroup = new aws.ec2.SecurityGroup(
    "gitlab-runners",
    {
        name: "Gitlab Runners",
        description: "Security perimeter for the Gitlab Runners",
        tags: {
            Name: "Gitlab Runners",
        },
    },
);
new aws.vpc.SecurityGroupIngressRule(  // FIXME: reduce?
    "gitlab-runners-managerAccess",
    {
        securityGroupId: gitlab_runners_securityGroup.id,
        description: "Allow all from Gitlab Runner autoscaling manager",
        referencedSecurityGroupId: gitlab_runner_autoscalingManager_securityGroup.id,
        ipProtocol: "-1",
    },
);
new aws.vpc.SecurityGroupEgressRule(  // FIXME: reduce?
    "gitlab-runners-internetAccess",
    {
        securityGroupId: gitlab_runners_securityGroup.id,
        description: "Allow all",
        cidrIpv4: "0.0.0.0/0",
        ipProtocol: "-1",
    },
);
// runners' security group - end

// runners - start
const gitlab_runners_userData = new cloudinit.Config(
    "gitlab-runners",
    {
        base64Encode: true,  // required by the launch template
        parts: [{
            filename: "cloud-config.docker-engine.yml",
            contentType: "text/cloud-config",
            content: yaml.stringify({
                packages: [ "docker" ],
                runcmd: [
                    "systemctl daemon-reload",
                    "systemctl enable --now docker.service",
                    "grep docker /etc/group -q && usermod -a -G docker ec2-user"
                ],
            }),
        }],
    },
);
const gitlab_runners_launchTemplate = new aws.ec2.LaunchTemplate(
    "gitlab-runners",
    {
        name: "GitlabRunners",
        imageId: ami_amazonLinux_x86_64_latest.apply(amis => amis.id),
        vpcSecurityGroupIds: [ gitlab_runners_securityGroup.id ],
        userData: gitlab_runners_userData.rendered,
    },
);
const gitlab_runners_autoScalingGroup = new aws.autoscaling.Group(
    "gitlab-runners",
    {
        name: "GitlabRunners",
        tags: [
            {
                key: "Owner",
                value: "infra@example.org",
                propagateAtLaunch: true,
            },
        ],
        vpcZoneIdentifiers: subnet_ids,
        minSize: 0,
        maxSize: 2,
        desiredCapacity: 0,
        mixedInstancesPolicy:{
            instancesDistribution: {
                onDemandBaseCapacity: 1,
                onDemandPercentageAboveBaseCapacity: 0,

                // be mindful of prices
                // https://docs.aws.amazon.com/autoscaling/ec2/userguide/allocation-strategies.html#spot-allocation-strategy
                spotAllocationStrategy: "price-capacity-optimized",
            },
            launchTemplate: {
                launchTemplateSpecification: {
                    launchTemplateId: gitlab_runners_launchTemplate.id,
                    version: "$Latest",
                },
                overrides: [
                    { instanceType: aws.ec2.InstanceType.M6a_XLarge },
                    { instanceType: aws.ec2.InstanceType.M6i_XLarge },
                    { instanceType: aws.ec2.InstanceType.M7a_XLarge },
                    { instanceType: aws.ec2.InstanceType.M7i_XLarge },
                ],
            },
        },
    },
);
// runners - end

// manager - start
const gitlab_runner_autoscalingManager_role = new aws.iam.Role(
    "gitlab-runner-autoscalingManager",
    {
        name: "GitlabRunnerAutoscalingManager",
        description: "Allow Gitlab Runner autoscaling managers to scale runner instances",
        assumeRolePolicy: JSON.stringify({
            Version: "2012-10-17",
            Statement: [{
                Sid: "AllowEc2ToAssumeThisVeryRole",
                Effect: "Allow",
                Principal: {
                    Service: "ec2.amazonaws.com",
                },
                Action: "sts:AssumeRole",
            }],
        }),
        managedPolicyArns: [
            "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",  // instance management via SSM
        ],
    },
);
pulumi.all([
    gitlab_runners_autoScalingGroup.arn,
    gitlab_runners_autoScalingGroup.name,
    awsRegion_output,
    callerIdentity_output,
]).apply(
    ([ asgArn, asgName, awsRegion, callerIdentity ]) => new aws.iam.RolePolicy(
        "gitlab-runner-autoscalingManager-inline-allowRoleFunctions",
        {
            role: gitlab_runner_autoscalingManager_role,
            name: "AllowRoleFunctions",
            policy: JSON.stringify({
                Version: "2012-10-17",
                Statement: [
                    {
                        Sid: "AllowAsgDiscovering",
                        Effect: "Allow",
                        Action: [
                            "autoscaling:DescribeAutoScalingGroups",
                            "ec2:DescribeInstances",
                        ],
                        Resource: "*"
                    },
                    {
                        Sid: "AllowAsgScaling",
                        Effect: "Allow",
                        Action: [
                            "autoscaling:SetDesiredCapacity",
                            "autoscaling:TerminateInstanceInAutoScalingGroup"
                        ],
                        Resource: asgArn,
                    },
                    {
                        Sid: "AllowManagingAccessToAsgInstances",
                        Effect: "Allow",
                        Action: "ec2-instance-connect:SendSSHPublicKey",
                        Resource: `arn:aws:ec2:${awsRegion.name}:${callerIdentity.accountId}:instance/*`,
                        Condition: {
                            StringEquals: {
                                "ec2:ResourceTag/aws:autoscaling:groupName": asgName,
                            },
                        },
                    },
                    {
                        Sid: "AllowAuthenticatingToEcr",
                        Effect: "Allow",
                        Action: "ecr:GetAuthorizationToken",
                        Resource: "*",
                    },
                    {
                        Sid: "AllowPullingImagesFromEcr",
                        Effect: "Allow",
                        Action: [
                            "ecr:BatchGetImage",
                            "ecr:GetDownloadUrlForLayer",
                        ],
                        Resource: "*",
                    },
                ],
            }),
        },

    ),
);
const gitlab_runner_autoscalingManager_instanceProfile = new aws.iam.InstanceProfile(
    "gitlab-runner-autoscalingManager",
    {
        name: "GitlabRunnerAutoscalingManager",
        role: gitlab_runner_autoscalingManager_role,
    },
    { protect: true }
);
const gitlab_runner_autoscalingManager_userData = pulumi.all([
    gitlab_runners_autoScalingGroup.name,
    awsRegion_output,
    callerIdentity_output,
    gitlab_url,
    token,
]).apply(
    ([ asgName, awsRegion, callerIdentity, gitlabUrl, token ]) => new cloudinit.Config(
        "gitlab-runner-autoscalingManager",
        {
            parts: [
                {
                    filename: "cloud-config.docker-engine.yml",
                    contentType: "text/cloud-config",
                    content: yaml.stringify({
                        package_upgrade: false,
                        packages: [
                            "docker",
                            "amazon-ecr-credential-helper",
                        ],
                        write_files: [
                            {
                                path: "/root/.docker/config.json",
                                permissions: "0644",
                                content: `{ "credsStore": "ecr-login" }`,
                            },
                        ],
                        runcmd: [
                            "systemctl daemon-reload",
                            "systemctl enable --now docker.service",
                        ],
                    }),
                },
                {
                    filename: "cloud-config.gitlab-runner.yml",
                    mergeType: "dict(recurse_array,no_replace)+list(append)",
                    contentType: "text/cloud-config",
                    content: yaml.stringify({
                        package_upgrade: false,
                        yum_repos: {
                            "gitlab-runner": {
                                name: "Gitlab Runner",
                                baseurl: "https://packages.gitlab.com/runner/gitlab-runner/amazon/2023/$basearch",
                                gpgcheck: true,
                                gpgkey: [
                                    "https://packages.gitlab.com/runner/gitlab-runner/gpgkey",
                                    "https://packages.gitlab.com/runner/gitlab-runner/gpgkey/runner-gitlab-runner-4C80FB51394521E9.pub.gpg",
                                    "https://packages.gitlab.com/runner/gitlab-runner/gpgkey/runner-gitlab-runner-49F16C5CC3A0F81F.pub.gpg",
                                ].join("\n"),
                                sslverify: true,
                                sslcacert: "/etc/pki/tls/certs/ca-bundle.crt",
                                metadata_expire: 300,
                            },
                        },
                        write_files: [
                            {
                                path: "/etc/gitlab-runner/config.toml",
                                permissions: "0600",
                                content: [
                                    `concurrent = 1`,
                                    `check_interval = 0`,
                                    `shutdown_timeout = 0`,
                                    ``,
                                    `[session_server]`,
                                    `  session_timeout = 1800`,
                                    ``,
                                    `[[runners]]`,
                                    `  name = "runner autoscaler"`,
                                    ``,
                                    `  url = "${gitlabUrl}"`,
                                    `  token = "${token}"`,
                                    ``,
                                    `  executor = "docker-autoscaler"`,
                                    `  environment = [ "AWS_REGION=${awsRegion.name}" ]`,
                                    ``,
                                    `  [runners.docker]`,
                                    `    privileged = false`,
                                    ``,
                                    `    image = "${callerIdentity.accountId}.dkr.ecr.${awsRegion.name}.amazonaws.com/some-repo/busybox:latest"`,
                                    `    pull_policy = [`,
                                    `      "if-not-present",`,
                                    `      "always"`,
                                    `    ]`,
                                    `    allowed_pull_policies = [`,
                                    `      "if-not-present",`,
                                    `      "always",`,
                                    `      "never"`,
                                    `    ]`,
                                    ``,
                                    `  [runners.autoscaler]`,
                                    `    plugin = "aws"`,
                                    ``,
                                    `    [runners.autoscaler.plugin_config]`,
                                    `      name = "${asgName}"`,
                                    ``,
                                    `    [[runners.autoscaler.policy]]`,
                                    `      periods = [ "* 7-19 * * mon-fri" ]`,
                                    `      timezone = "Europe/Amsterdam"`,
                                    `      idle_count = 1`,
                                    `      idle_time = "20m0s"`,
                                ].join("\n"),  // FIXME: granted, this sucks but at least I can interpolate in it
                            },
                            {
                                path: "/root/.aws/config",
                                permissions: "0600",
                                content: [
                                    `[default]`,
                                    `region = ${awsRegion.name}`,
                                ].join("\n"),
                            },
                        ],
                        packages: [ "gitlab-runner-17.4.0" ],
                        runcmd: [
                            "systemctl daemon-reload",
                            "systemctl enable --now 'gitlab-runner'",
                            "gitlab-runner fleeting install",
                        ],
                    }),
                },
            ],
        },

    ),
);
new aws.ec2.Instance(
    "gitlab-runner-autoscalingManager",
    {
        tags: {
            Name: "Gitlab Runner autoscaling manager",
        },
        ami: ami_amazonLinux_arm64_latest.apply(ami => ami.id),
        instanceType: aws.ec2.InstanceType.T4g_Micro,
        iamInstanceProfile: gitlab_runner_autoscalingManager_instanceProfile,
        subnetId: subnet_ids[0],
        associatePublicIpAddress: false,
        vpcSecurityGroupIds: [ gitlab_runner_autoscalingManager_securityGroup.id ],
        userData: gitlab_runner_autoscalingManager_userData.rendered,
    },
);
// manager - end
