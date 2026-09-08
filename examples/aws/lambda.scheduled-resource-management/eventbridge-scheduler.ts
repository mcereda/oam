/*
 * EventBridge Scheduler configuration for nightly stop / morning start.
 */

import * as aws from '@pulumi/aws';
import * as pulumi from '@pulumi/pulumi';

/*
 * Prerequisites
 * ---
 * `resourceControllerLambda` will be the Lambda function that stops and starts
 * resources. The implementation is language-agnostic.
 */

declare const resourceControllerLambda: aws.lambda.Function;

/**
 * Scheduler IAM role
 * ---
 * EventBridge Scheduler needs its own role with `scheduler.amazonaws.com` as
 * the trust principal. The role's only permission is invoking the Lambda.
 */
const schedulerRole = new aws.iam.Role('resource-scheduler', {
    assumeRolePolicy: aws.iam.assumeRolePolicyForPrincipal({
        Service: 'scheduler.amazonaws.com',
    }),
    inlinePolicies: [{
        name: 'invoke-lambda',
        policy: pulumi.jsonStringify({
            Statement: [{
                Effect: 'Allow',
                Action: [ 'lambda:InvokeFunction' ],
                Resource: [ resourceControllerLambda.arn ],
            }],
        }),
    }],
});

/**
 * Nightly stop
 * ---
 * Run daily (including weekends) to address RDS' 7-day force-start, as an
 * instance stopped for 7 consecutive days is automatically started by RDS, and
 * the only containment is stopping it again within 24 hours.
 *
 * AWS cron quirk: either day-of-month or day-of-week must be `?`, not `*`.
 */
new aws.scheduler.Schedule('nightly-stop', {
    scheduleExpression: 'cron(30 19 * * ? *)',   // daily at 19:30 UTC
    scheduleExpressionTimezone: 'UTC',
    flexibleTimeWindow: { mode: 'OFF' },
    target: {
        arn: resourceControllerLambda.arn,
        roleArn: schedulerRole.arn,
        input: pulumi.jsonStringify({
            action: 'stop',
            source: 'scheduler',
            resources: [
                /*
                 * Full workday + on-demand-only resources.
                 * On-demand-only resources (not in the morning start list) are
                 * stopped nightly and started manually when needed.
                 */
                { type: 'ecs', cluster: 'staging', service: 'api' },
                { type: 'ecs', cluster: 'staging', service: 'worker' },
                { type: 'rds', id: 'staging-postgres' },
                // on-demand
                { type: 'ecs', cluster: 'staging', service: 'grafana' },
                { type: 'rds', id: 'awx-staging' },
            ],
        }),
    },
});

/**
 * Morning start
 * ---
 * Weekdays only. Weekend stop runs are no-ops for already-stopped resources.
 * Resources absent from this list are on-demand only (started via Slack, CLI,
 * or CI pipeline when needed).
 */
new aws.scheduler.Schedule('morning-start', {
    scheduleExpression: 'cron(0 6 ? * MON-FRI *)',  // weekdays at 06:00 UTC
    scheduleExpressionTimezone: 'UTC',
    flexibleTimeWindow: { mode: 'OFF' },
    target: {
        arn: resourceControllerLambda.arn,
        roleArn: schedulerRole.arn,
        input: pulumi.jsonStringify({
            action: 'start',
            source: 'scheduler',
            resources: [
                /*
                 * Full workday resources only.
                 * Start order matters when resources have dependencies:
                 * the Lambda should start databases before compute.
                 */
                { type: 'rds', id: 'staging-postgres' },
                { type: 'ecs', cluster: 'staging', service: 'api', desiredCount: 2 },
                { type: 'ecs', cluster: 'staging', service: 'worker', desiredCount: 1 },
            ],
        }),
    },
});
