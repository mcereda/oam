# Lambda

Runs code in response to events without provisioning or managing servers (not that the user can see, anyway).

1. [TL;DR](#tldr)
1. [Deployment](#deployment)
   1. [As archived code](#as-archived-code)
1. [Example: scheduled resource management](#example-scheduled-resource-management)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Functions are deployed as archived code (`.zip`) or container images.<br/>
The service creates execution environments on demand and recycles them after a period of inactivity.

Functions can be triggered by invoking them directly and by other AWS services (S3 events, API Gateway requests,
[EventBridge] schedules, [SQS] messages, [SNS] notifications, etc.).

> [!warning] IAM role deletions are not guarded by AWS
> AWS does **not** check whether a role being deleted is actively attached to a Lambda function. When such a role is
> deleted, the function simply and silently ends up with a dangling role reference.

Lambda supports environment variables up to a **hard** limit of **4 KB** across all variables and values combined.<br/>
Consider keeping at least the large configuration values out of environment variables, and bundle them with the code
instead (e.g., as a `config.json` file inside the Lambda's package) so that the function can read them from the
execution environment during cold start.

## Deployment

### As archived code

1. Archive the code (as `.zip`) and upload it to [S3].
1. Point the Lambda function to that archive.

During a **cold** start, Lambda downloads the configured archive from S3 and extracts it to `/var/task/` in the
function's execution environment. Its working directory contains all the files in the archive, side by side.<br/>
This allows including data alongside the code (e.g., configuration files and blobs).

## Example: scheduled resource management

Non-production resources (staging databases, development services, CI runners) running 24/7 waste a significant portion
of their cost on hours nobody is using them. A development RDS instance left running through nights and weekends
accumulates roughly 76% of its cost during unattended hours (128 of 168 hours per week).

A Lambda function triggered by [EventBridge Scheduler] to stop resources in the evening and start them in the morning is
the simplest and most cost-effective way to reclaim that spend. The Lambda itself costs essentially nothing to run (a few
seconds of execution per day), while the savings are proportional to the full hourly cost of each stopped resource.

The [example's README][example readme] has the full specification: per-service API operations, safety rails, dependency
ordering, alarm suppression, observability, EventBridge Scheduler configuration, IAM permissions, and design boundaries.

| File | What |
| ---- | ---- |
| [`README.md`][example readme] | Full spec: architecture, resource types, safety rails, dependency ordering, alarm suppression, observability, scheduler config, IAM, design boundaries. |
| [`function.py`][function example] | Python Lambda handler with Slack slash commands (3-second ack pattern) and IAM-authenticated HTTP. |
| [`config.json`][config example] | Configuration structure: aliases with dependency edges, default counts, resource registry, scheduler target lists. |
| [`eventbridge-scheduler.ts`][eventbridge-scheduler example] | Pulumi IaC for the EventBridge Scheduler schedules and IAM role. |

## Further readings

- [Amazon Web Services]
- [AWS Lambda Developer Guide]
- [Best practices for working with AWS Lambda functions]
- [EventBridge]
- [EC2]
- [RDS]
- [ECS]

### Sources

- [AWS Lambda Developer Guide]
- [Best practices for working with AWS Lambda functions]
- [EventBridge Scheduler]
- [Stopping an Amazon RDS DB instance temporarily]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[Amazon Web Services]: README.md
[EC2]: ec2.md
[ECS]: ecs.md
[EventBridge]: README.md#eventbridge
[RDS]: rds.md
[S3]: s3.md
[SNS]: sns.md
[SQS]: sqs.md

<!-- Files -->
[config example]: ../../../examples/aws/lambda.scheduled-resource-management/config.json
[eventbridge-scheduler example]: ../../../examples/aws/lambda.scheduled-resource-management/eventbridge-scheduler.ts
[example readme]: ../../../examples/aws/lambda.scheduled-resource-management/README.md
[function example]: ../../../examples/aws/lambda.scheduled-resource-management/function.py

<!-- Upstream -->
[AWS Lambda Developer Guide]: https://docs.aws.amazon.com/lambda/latest/dg/welcome.html
[Best practices for working with AWS Lambda functions]: https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html
[EventBridge Scheduler]: https://docs.aws.amazon.com/scheduler/latest/UserGuide/what-is-scheduler.html
[Stopping an Amazon RDS DB instance temporarily]: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_StopInstance.html
