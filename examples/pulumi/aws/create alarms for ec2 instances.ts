import * as aws from "@pulumi/aws";
import * as pulumi from "@pulumi/pulumi";

/**
 * Creates CloudWatch alarms for EC2 instances.
 *
 * Refer <https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Best_Practice_Recommended_Alarms_AWS_Services.html#EC2>
 * for details on the alarms.
 *
 * @param instance The EC2 instance to create alarms for
 * @param topic The SNS topic to send notifications to
 * @param namePrefix The prefix to use for the alarms' name (defaults to the instance's ID)
 * @param [cpuUtilization=true] Whether to create an alarm for the instance's CPUUtilization metric
 * @param [instanceStatusCheck=true] Whether to create an alarm for the instance's instance status check
 * @param [systemStatusCheck=true] Whether to create an alarm for the instance's system status check
 * @param [memUsedPercent=false] Whether to create an alarm for the instance's mem_used_percent metric
 * @param [diskUsedPercent=false] Whether to create an alarm for the instance's disk_used_percent metric
 * @param [extraTags={}] Extra tags to apply to the alarms
 * @param [protectFromDeletion=true] Whether to protect the alarms from deletion
 * @returns An object with the alarms that were created
 */
export function createCloudwatchAlarmsForEc2Instance(
    ec2Instance: aws.ec2.Instance | pulumi.Output<aws.ec2.Instance> | pulumi.Output<aws.ec2.GetInstanceResult>,
    snsTopic?: aws.sns.Topic | pulumi.Output<aws.sns.Topic> | pulumi.Output<aws.sns.GetTopicResult>,
    namePrefix: string | pulumi.Output<string> = pulumi.interpolate `${ ec2Instance.id }`,
    cpuUtilization: boolean = true,
    instanceStatusCheck: boolean = true,
    systemStatusCheck: boolean = true,
    memUsedPercent: boolean = false,  // requires CWAgent configured
    diskUsedPercent: boolean = false,  // requires CWAgent configured
    extraTags: { [key: string]: string } = {},
    protectFromDeletion: boolean = true,
) {
    namePrefix = pulumi.interpolate `${ namePrefix }`;
    const idPrefix = pulumi.interpolate `${ namePrefix.apply((s: string) => s.replace('_','-').replace(/-?\w/g, match => match.toLowerCase()))}`;
    const ec2InstanceId = pulumi.interpolate `${ ec2Instance.id }`;
    const snsTopicArn = snsTopic !== undefined ? pulumi.interpolate `${ snsTopic.arn }` : undefined;

    /**
     * Helps monitoring the CPU utilization of an EC2 instance.
     *
     * Depending on the application, consistently high utilization levels might be normal. But if performance is
     * degraded, and the application is not constrained by disk I/O, memory, or network resources, then a maxed-out CPU
     * might indicate a resource bottleneck or application performance problems.
     * High CPU utilization might indicate that an upgrade to a more CPU intensive instance is required.
     * If detailed monitoring is enabled, one can change the period to 60 seconds instead of 300 seconds.
     *
     * This alarm will trigger when the CPU utilization is > 80% for 3 consecutive times over 15 minutes.
     * It only sends a notification to the given SNS topics (if any was given).
     */
    const cpuUtilization_cloudwatchMetricAlarm = cpuUtilization ? pulumi
        .all([ idPrefix, namePrefix, ec2InstanceId, snsTopicArn ])
        .apply(
            ([ idPrefix, namePrefix, instanceId, topicArn ]: [ string, string, string, aws.ARN|undefined ]) =>
            new aws.cloudwatch.MetricAlarm(
                `${ idPrefix }-cpuUtilization`,
                {
                    name: `${ namePrefix }_CPUUtilization`,
                    alarmDescription: "Notify the team when the CPU utilization is > 80% 3 consecutive times over 15 minutes.",
                    tags: {
                        Controls: "SOC2/CC7.2",
                        ...extraTags,
                    },

                    namespace: "AWS/EC2",
                    dimensions: {
                        InstanceId: instanceId,
                    },
                    metricName: "CPUUtilization",
                    statistic: "Average",
                    comparisonOperator: "GreaterThanThreshold",
                    threshold:  80,
                    period: 300,
                    evaluationPeriods: 3,
                    datapointsToAlarm: 3,
                    alarmActions: [
                        topicArn,
                    ].filter(item => item !== undefined),
                },
                {
                    protect: protectFromDeletion,
                },
            ),
        ) : undefined;

    /**
     * Helps monitoring an instance's InstanceStatus check.
     *
     * This alarm is used to detect underlying problems with instances.
     * Should this status check fail, this alarm should be in ALARM state.
     *
     * This alarm will trigger when the Instance status check fails 2 consecutive times over 10 minutes.
     * It:
     *  - sends a notification to the given SNS topics (if any was given);
     *  - tries to automatically restart the instance.
     */
    const instanceStatusCheck_cloudwatchMetricAlarm = instanceStatusCheck ? pulumi
        .all([ idPrefix, namePrefix, ec2InstanceId, snsTopicArn ])
        .apply(
            ([ idPrefix, namePrefix, instanceId, topicArn ]: [ string, string, string, aws.ARN|undefined ]) =>
            new aws.cloudwatch.MetricAlarm(
                `${ idPrefix }-instanceStatusCheck`,
                {
                    name: `${ namePrefix ?? ec2InstanceId }_InstanceStatusCheck`,
                    alarmDescription: "Notify the team and restart the instance when the Instance status check fails 2 consecutive times over 10 minutes.",
                    tags: {
                        Controls: "SOC2/CC7.2",
                        ...extraTags,
                    },

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
                        topicArn,
                        "arn:aws:swf:eu-west-1:012345678901:action/actions/AWS_EC2.InstanceId.Reboot/1.0",
                    ].filter(item => item !== undefined),
                },
                {
                    protect: protectFromDeletion,
                },
            ),
        ) : undefined;

    /**
     * Helps monitoring an instance's SystemStatus check.
     *
     * This alarm is used to detect underlying problems with instances.
     * Should this status check fail, this alarm should be in the ALARM state.
     *
     * This alarm will trigger when the System status check fails 2 consecutive times over 10 minutes.
     * It:
     *  - sends a notification to the given SNS topics (if any was given);
     *  - tries to automatically recover the instance.
     */
    const systemStatusCheck_cloudwatchMetricAlarm = systemStatusCheck ? pulumi
        .all([ idPrefix, namePrefix, ec2InstanceId, snsTopicArn ])
        .apply(
            ([ idPrefix, namePrefix, instanceId, topicArn ]: [ string, string, string, aws.ARN|undefined ]) =>
            new aws.cloudwatch.MetricAlarm(
                `${ idPrefix }-systemStatusCheck`,
                {
                    name: `${ namePrefix ?? ec2InstanceId }_SystemStatusCheck`,
                    alarmDescription: "Notify the team and recover the instance when the System status check fails 2 consecutive times over 10 minutes.",
                    tags: {
                        Controls: "SOC2/CC7.2",
                        ...extraTags,
                    },

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
                        topicArn,
                        "arn:aws:automate:eu-west-1:ec2:recover",
                    ].filter(item => item !== undefined),
                },
                {
                    protect: protectFromDeletion,
                },
            ),
        ) : undefined;

    /**
     * Helps monitoring the memory utilization of an EC2 instance.
     *
     * High memory utilization might indicate that an upgrade to a more memory oriented instance is required.
     *
     * This alarm requires the CloudWatch Agent to be configured to send mem_used_percent data.
     *
     * This alarm will trigger when the memory utilization is > 85% for 3 consecutive times over 15 minutes.
     * It only sends a notification to the given SNS topics (if any was given).
     */
    const memUsedPercent_cloudwatchMetricAlarm = memUsedPercent ? pulumi
        .all([ idPrefix, namePrefix, ec2InstanceId, snsTopicArn ])
        .apply(
            ([ idPrefix, namePrefix, instanceId, topicArn ]: [ string, string, string, aws.ARN|undefined ]) =>
            new aws.cloudwatch.MetricAlarm(
                `${ idPrefix }-memUsedPercent`,
                {
                    name: `${ namePrefix ?? ec2InstanceId }_MemUsedPercent`,
                    alarmDescription: "Notify the team when the memory utilization is > 85% 3 consecutive times over 15 minutes.",
                    tags: {
                        Controls: "SOC2/CC7.2",
                        ...extraTags,
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
                        topicArn,
                    ].filter(item => item !== undefined),
                },
                {
                    protect: protectFromDeletion,
                },
            ),
        ) : undefined;

    /**
     * Helps monitoring the disk utilization of an EC2 instance.
     *
     * This alarm requires the CloudWatch Agent to be configured to send disk_used_percent data.
     *
     * This alarm will trigger when the disk utilization is > 85% for 3 consecutive times over 15 minutes.
     * It only sends a notification to the given SNS topics (if any was given).
     */
    const diskUsedPercent_cloudwatchMetricAlarm = diskUsedPercent ? pulumi
        .all([ idPrefix, namePrefix, ec2InstanceId, snsTopicArn ])
        .apply(
            ([ idPrefix, namePrefix, instanceId, topicArn ]: [ string, string, string, aws.ARN|undefined ]) =>
            new aws.cloudwatch.MetricAlarm(
                `${ idPrefix }-diskUsedPercent`,
                {
                    name: `${ namePrefix ?? ec2InstanceId }_DiskUsedPercent`,
                    alarmDescription: "Notify the team when the disk utilization is > 85% 3 consecutive times over 15 minutes.",
                    tags: {
                        Controls: "SOC2/CC7.2",
                        ...extraTags,
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
                        topicArn,
                    ].filter(item => item !== undefined),
                },
                {
                    protect: protectFromDeletion,
                },
            ),
        ) : undefined;

    return {
        cpuUtilization: cpuUtilization_cloudwatchMetricAlarm,
        instanceStatusCheck: instanceStatusCheck_cloudwatchMetricAlarm,
        systemStatusCheck: systemStatusCheck_cloudwatchMetricAlarm,
        memUsedPercent: memUsedPercent_cloudwatchMetricAlarm,
        diskUsedPercent: diskUsedPercent_cloudwatchMetricAlarm,
    } as const;
};
