import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";

const instance_output = aws.ec2.getInstanceOutput({
    filters: [{
        name: "tag:Name",
        values: [ "instance-name-tag" ],
    }],
});

const iamRole = new aws.iam.Role(
    "awsChatbot",
    {
        name: "AWSChatbotRole",
        assumeRolePolicy: JSON.stringify({
            Version: "2012-10-17",
            Statement: [{
                Effect: "Allow",
                Principal: {
                    Service: "chatbot.amazonaws.com",
                },
                Action: "sts:AssumeRole",
            }],
        }),
    },
);
new aws.iam.RolePolicy(
    "awsChatbot",
    {
        name: "AllowRoleFunctions",
        description: "NotificationsOnly policy for AWS-Chatbot",
        policy: JSON.stringify({
            Version: "2012-10-17",
            Statement: [{
                Effect: "Allow",
                Action: [
                    "cloudwatch:Describe*",
                    "cloudwatch:Get*",
                    "cloudwatch:List*",
                ],
                "Resource": "*",
            }],
        }),
    },
);

const notifications_snsTopic = new aws.sns.Topic(
    "notifications",
    { name: "notifications" },
);
new aws.sns.TopicSubscription(
    // FIXME: requires manual confirmation from email
    "notifications-email",
    {
        topic: notifications_snsTopic.arn,
        protocol: "email",
        endpoint: "infra@example.org",
    },
);
new aws.chatbot.SlackChannelConfiguration(
    "notifications-channel",
    {
        configurationName: "Notifications2Channel",
        slackTeamId: "T00000000",
        slackChannelId: "C0000000000",
        snsTopicArns: [ notifications_snsTopic.arn ],
        iamRoleArn: iamRole.arn,
        guardrailPolicyArns: [ "arn:aws:iam::aws:policy/ReadOnlyAccess" ],
    },
);

pulumi.
    all([ instance_output.id, instance_output.ami, instance_output.instanceType ])
    .apply( ([ instanceId, instanceAmi, instanceType ]: [ string, string, string ] ) => {
        // refer https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html#EC2

        new aws.cloudwatch.MetricAlarm(
            `${instanceId}_systemStatus`,
            {
                name: `${instanceId}_SystemStatus`,
                alarmDescription: "Notify on Slack and recover the instance when the System status check fails 2 consecutive times over 10 minutes.",

                namespace: "AWS/EC2",
                dimensions: {
                    InstanceId: instanceId,
                },
                metricName: "StatusCheckFailed_System",
                statistic: "Maximum",
                unit: "Count",
                comparisonOperator: "GreaterThanOrEqualToThreshold",
                threshold: 1,
                period: 300,
                evaluationPeriods: 2,
                datapointsToAlarm: 2,
                alarmActions: [
                    notifications_snsTopic.arn,
                    "arn:aws:automate:eu-west-1:ec2:recover",
                ],
                okActions: [
                    notifications_snsTopic.arn,
                ],
            },
        );

        new aws.cloudwatch.MetricAlarm(
            `${instanceId}_instanceStatus`,
            {
                name: `${instanceId}_InstanceStatus`,
                alarmDescription: "Notify on Slack and restart the instance when the Instance status check fails 2 consecutive times over 10 minutes.",

                namespace: "AWS/EC2",
                dimensions: {
                    InstanceId: instanceId,
                },
                metricName: "StatusCheckFailed_Instance",
                statistic: "Maximum",
                unit: "Count",
                comparisonOperator: "GreaterThanOrEqualToThreshold",
                threshold: 1,
                period: 300,
                evaluationPeriods: 2,
                datapointsToAlarm: 2,
                alarmActions: [
                    notifications_snsTopic.arn,
                    "arn:aws:swf:eu-west-1:012345678901:action/actions/AWS_EC2.InstanceId.Reboot/1.0",
                ],
                okActions: [
                    notifications_snsTopic.arn,
                ],
            },
        );

        new aws.cloudwatch.MetricAlarm(
            `${instanceId}-cpuUtilization`,
            {
                name: `${instanceId}_CPUUtilization`,
                alarmDescription: "Notify on Slack when the CPU utilization is above 80% 3 consecutive times over 15 minutes.",
                tags: {
                    Controls: "SOC2/CC7.2",
                },

                namespace: "AWS/EC2",
                dimensions: {
                    InstanceId: instanceId
                },
                metricName: "CPUUtilization",
                statistic: "Average",
                comparisonOperator: "GreaterThanThreshold",
                threshold:  80,
                period: 300,
                evaluationPeriods: 3,
                datapointsToAlarm: 3,
                alarmActions: [
                    notifications_snsTopic.arn,
                ],
                okActions: [
                    notifications_snsTopic.arn,
                ],
            },
        );

        // requires the host to have the cloudwatch agent installed and configured to send 'mem_used_percent' metrics
        new aws.cloudwatch.MetricAlarm(
            `${instanceId}-memUsedPercent`,
            {
                name: `${instanceId}_MemUsedPercent`,
                alarmDescription: "Notify on Slack when the memory utilization is > 85% 3 consecutive times over 15 minutes.",
                tags: {
                    Controls: "SOC2/CC7.2",  // FIXME
                },

                namespace: "CWAgent",
                dimensions: {
                    InstanceId: instanceId,
                },
                metricName: "mem_used_percent",
                statistic: "Average",
                comparisonOperator: "GreaterThanThreshold",
                threshold: 85,
                period: 300,
                evaluationPeriods: 3,
                datapointsToAlarm: 3,
                alarmActions: [
                    notifications_snsTopic.arn,
                ],
                okActions: [
                    notifications_snsTopic.arn,
                ],
            },
        );

        // requires the host to have the cloudwatch agent installed and configured to send 'disk_used_percent' metrics
        new aws.cloudwatch.MetricAlarm(
            `${instanceId}-diskUsedPercent`,
            {
                name: `${instanceId}_DiskUsedPercent`,
                alarmDescription: "Notify on Slack when the disk utilization is > 85% 3 consecutive times over 15 minutes.",
                tags: {
                    Controls: "SOC2/CC7.2",  // FIXME
                },

                namespace: "CWAgent",
                dimensions: {
                    InstanceId: instanceId,
                },
                metricName: "disk_used_percent",
                statistic: "Average",
                comparisonOperator: "GreaterThanThreshold",
                threshold: 85,
                period: 300,
                evaluationPeriods: 3,
                datapointsToAlarm: 3,
                alarmActions: [
                    notifications_snsTopic.arn,
                ],
                okActions: [
                    notifications_snsTopic.arn,
                ],
            },
        );
        new aws.cloudwatch.MetricAlarm(
            `${instanceId}-diskUsedPercent`,
            {
                name: `${instanceId}_DiskUsedPercent_rootDisk`,
                alarmDescription: "Notify on Slack when the root disk utilization is > 85% 3 consecutive times over 15 minutes.",
                tags: {
                    Controls: "SOC2/CC7.2",  // FIXME
                },

                namespace: "CWAgent",
                dimensions: {
                    InstanceId: instanceId,
                    ImageId: instanceAmi,
                    InstanceType: instanceType,
                    device: "nvme0n1p1",
                    fstype: "xfs",
                    path: "/",
                },
                metricName: "disk_used_percent",
                statistic: "Average",
                comparisonOperator: "GreaterThanThreshold",
                threshold: 85,
                period: 300,
                evaluationPeriods: 3,
                datapointsToAlarm: 3,
                alarmActions: [
                    notifications_snsTopic.arn,
                ],
                okActions: [
                    notifications_snsTopic.arn,
                ],
            },
        );

    });
