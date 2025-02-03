import * as aws from "@pulumi/aws";

const instance_output = new aws.ec2.getInstanceOutput({
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

new aws.cloudwatch.MetricAlarm(
    "prometheusServer_systemStatus",
    {
        name: "PrometheusServer_SystemStatus",
        alarmDescription: "Notify and recover when the System status check fails 5 consecutive times over 5 minutes.",

        namespace: "AWS/EC2",
        dimensions: {
            InstanceId: instance_output.id,
        },
        metricName: "StatusCheckFailed_System",
        statistic: "Maximum",
        unit: "Count",
        comparisonOperator: "GreaterThanOrEqualToThreshold",
        threshold: 1,
        evaluationPeriods: 5,
        period: 60,
        alarmActions: [
            notifications_snsTopic.arn,
            "arn:aws:automate:eu-west-1:ec2:recover",
        ],
    },
);
new aws.cloudwatch.MetricAlarm(
    "prometheusServer_instanceStatus",
    {
        name: "PrometheusServer_instanceStatus",
        alarmDescription: "Notify and reboot when the Instance status check fails 5 consecutive times over 5 minutes.",

        namespace: "AWS/EC2",
        dimensions: {
            InstanceId: instance_output.id,
        },
        metricName: "StatusCheckFailed_Instance",
        statistic: "Maximum",
        unit: "Count",
        comparisonOperator: "GreaterThanOrEqualToThreshold",
        threshold: 1,
        evaluationPeriods: 5,
        period: 60,
        alarmActions: [
            notifications_snsTopic.arn,
            "arn:aws:swf:eu-west-1:012345678901:action/actions/AWS_EC2.InstanceId.Reboot/1.0",
        ],
    },
);
