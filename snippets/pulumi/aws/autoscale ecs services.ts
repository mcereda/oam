import * as pulumi from '@pulumi/pulumi';
import * as aws from '@pulumi/aws';

const cluster: pulumi.Output<aws.ecs.GetClusterResult> = aws.ecs.getClusterOutput({ clusterName: 'devel' });
const service: pulumi.Output<aws.ecs.GetServiceResult> = aws.ecs.getServiceOutput({
    clusterArn: cluster.arn,
    serviceName: 'someService',
});
const targetGroup = aws.alb.getTargetGroupOutput({
    arn: service.loadBalancers.apply(albs => albs![0].targetGroupArn!),
});
const loadBalancer = aws.alb.getLoadBalancerOutput({ arn: targetGroup.loadBalancerArns[0] });

const autoscalingTarget = new aws.appautoscaling.Target(
    `${service.serviceName}`,
    {
        resourceId: pulumi.interpolate `service/${cluster.clusterName}/${service.name}`,
        serviceNamespace: 'ecs',
        scalableDimension: 'ecs:service:DesiredCount',
        minCapacity: 1,
        maxCapacity: 3,
    },
);
new aws.appautoscaling.Policy(
    `${service.serviceName}-averageCpuUtilization`,
    {
        name: 'Scale on Average CPU Utilization',
        policyType: "TargetTrackingScaling",

        resourceId: autoscalingTarget.resourceId,
        serviceNamespace: autoscalingTarget.serviceNamespace,
        scalableDimension: autoscalingTarget.scalableDimension,
        targetTrackingScalingPolicyConfiguration: {
            predefinedMetricSpecification: {
                predefinedMetricType: "ECSServiceAverageCPUUtilization",
            },
            targetValue: 75.0,
            scaleInCooldown: 60,
            scaleOutCooldown: 60,
        },
    },
);
new aws.appautoscaling.Policy(
    `${service.serviceName}-averageMemoryUtilization`,
    {
        name: 'Scale on Average Memory Utilization',
        policyType: "TargetTrackingScaling",

        resourceId: autoscalingTarget.resourceId,
        serviceNamespace: autoscalingTarget.serviceNamespace,
        scalableDimension: autoscalingTarget.scalableDimension,
        targetTrackingScalingPolicyConfiguration: {
            predefinedMetricSpecification: {
                predefinedMetricType: "ECSServiceAverageMemoryUtilization",
            },
            targetValue: 75.0,
            scaleInCooldown: 60,
            scaleOutCooldown: 60,
        },
    },
);
new aws.appautoscaling.Policy(
    `${service.serviceName}-albRequestCountPerTarget`,
    {
        name: 'Scale on ALB Request Count',
        policyType: "TargetTrackingScaling",

        resourceId: autoscalingTarget.resourceId,
        serviceNamespace: autoscalingTarget.serviceNamespace,
        scalableDimension: autoscalingTarget.scalableDimension,
        targetTrackingScalingPolicyConfiguration: {
            predefinedMetricSpecification: {
                predefinedMetricType: "ALBRequestCountPerTarget",
                resourceLabel: pulumi.interpolate `${loadBalancer.arnSuffix}/${targetGroup.arnSuffix}`,
            },
            targetValue: 12.0,
            scaleInCooldown: 60,
            scaleOutCooldown: 60,
        },
    },
);
