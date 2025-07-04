# Elastic Container Service

1. [TL;DR](#tldr)
1. [How it works](#how-it-works)
   1. [EC2 launch type](#ec2-launch-type)
   1. [Fargate launch type](#fargate-launch-type)
   1. [Standalone tasks](#standalone-tasks)
   1. [Services](#services)
1. [Capacity providers](#capacity-providers)
   1. [EC2 capacity providers](#ec2-capacity-providers)
   1. [Fargate for ECS](#fargate-for-ecs)
1. [Resource constraints](#resource-constraints)
1. [Environment variables](#environment-variables)
1. [Storage](#storage)
   1. [EBS volumes](#ebs-volumes)
   1. [EFS volumes](#efs-volumes)
   1. [Docker volumes](#docker-volumes)
   1. [Bind mounts](#bind-mounts)
1. [Execute commands in tasks' containers](#execute-commands-in-tasks-containers)
1. [Scale the number of tasks automatically](#scale-the-number-of-tasks-automatically)
   1. [Target tracking](#target-tracking)
1. [Allow tasks to communicate with each other](#allow-tasks-to-communicate-with-each-other)
   1. [ECS Service Connect](#ecs-service-connect)
   1. [ECS service discovery](#ecs-service-discovery)
   1. [VPC Lattice](#vpc-lattice)
1. [Scrape metrics using Prometheus](#scrape-metrics-using-prometheus)
1. [Send logs to a central location](#send-logs-to-a-central-location)
    1. [FireLens](#firelens)
    1. [Fluent Bit or Fluentd](#fluent-bit-or-fluentd)
1. [Troubleshooting](#troubleshooting)
    1. [Invalid 'cpu' setting for task](#invalid-cpu-setting-for-task)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

_Tasks_ are the basic unit of deployment.<br/>
They are instances of the set of containers specified in their own _task definition_.

Tasks model and run one or more containers, much like Pods in Kubernetes.<br/>
Containers **cannot** run on ECS unless encapsulated in a task.

_Standalone tasks_ start a single task, which is meant to perform some work to completion and then stop (much like batch
processes would).<br/>
_Services_ run and maintain a defined number of instances of the same task simultaneously, which are meant to stay
active and act as replicas of some service (much like web servers would).

Tasks are executed depending on their _launch type_ and _capacity providers_:

- On EC2 instances that one owns, manages, and pays for.
- On Fargate (an AWS-managed serverless environment for containers execution).

Unless explicitly restricted or capped, containers in tasks get access to all the CPU and memory capacity available on
the host running it.

By default, containers behave like other Linux processes with respect to access to resources like CPU and memory.<br/>
Unless explicitly protected and guaranteed, all containers running on the same host share CPU, memory, and other
resources much like normal processes running on that host share those very same resources.

<details>
  <summary>Usage</summary>

```sh
# List services.
aws ecs list-services --cluster 'clusterName'

# Scale services.
aws ecs update-service --cluster 'clusterName' --service 'serviceName' --desired-count '0'
aws ecs update-service --cluster 'clusterName' --service 'serviceName' --desired-count '10'

# Wait for services to be running.
aws ecs wait services-stable --cluster 'clusterName' --services 'serviceName' …

# Delete services.
# Cannot really be deleted if scaled above 0.
aws ecs delete-service --cluster 'clusterName' --service 'serviceName'
aws ecs delete-service --cluster 'clusterName' --service 'serviceName' --force

# List task definitions.
aws ecs list-task-definitions --family-prefix 'familyPrefix'

# Deregister task definitions.
aws ecs deregister-task-definition --task-definition 'taskDefinitionArn'

# Delete task definitions.
# The task definition must be deregistered.
aws ecs delete-task-definitions --task-definitions 'taskDefinitionArn' …

# List tasks.
aws ecs list-tasks --cluster 'clusterName'
aws ecs list-tasks --cluster 'clusterName' --service-name 'serviceName'

# Get information about tasks.
aws ecs describe-tasks --cluster 'clusterName' --tasks 'taskIdOrArn' …

# Wait for tasks to be running.
aws ecs wait tasks-running --cluster 'clusterName' --tasks 'taskIdOrArn' …

# Access shells on containers in ECS.
aws ecs execute-command \
  --cluster 'clusterName' --task 'taskId' --container 'containerName' \
  --interactive --command '/bin/bash'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Get the ARNs of tasks for specific services.
aws ecs list-tasks --cluster 'testCluster' --service-name 'testService' --query 'taskArns' --output 'text'

# Get the private IP Address of containers.
aws ecs describe-tasks --output 'text' \
  --cluster 'testCluster' --tasks 'testTask' \
  --query "tasks[].attachments[].details[?(name=='privateDnsName')].value"

# Connect to the private DNS name of containers in ECS.
curl -fs "http://$(\
  aws ecs describe-tasks --cluster 'testCluster' --tasks "$(\
      aws ecs list-tasks --cluster 'testCluster' --service-name 'testService' --query 'taskArns' --output 'text' \
  )" --query "tasks[].attachments[].details[?(name=='privateDnsName')].value" --output 'text' \
):8080"

# Delete services.
aws ecs delete-service --cluster 'testCluster' --service 'testService' --force

# Delete task definitions.
aws ecs list-task-definitions --family-prefix 'testService' --output 'text' --query 'taskDefinitionArns' \
| xargs -n '1' aws ecs deregister-task-definition --task-definition

# Wait for tasks to be running.
aws ecs list-tasks --cluster 'testCluster' --family 'testService' --output 'text' --query 'taskArns' \
| xargs -p aws ecs wait tasks-running --cluster 'testCluster' --tasks
while [[ $(aws ecs list-tasks --query 'taskArns' --output 'text' --cluster 'testCluster' --service-name 'testService') == "" ]]; do sleep 1; done

# Restart tasks.
# No real way to do that, just stop the tasks and new ones will be eventually started in their place.
# To mimic a blue-green deployment, scale the service up by doubling its tasks, then down again to the normal amount.

```

</details>

## How it works

Tasks must be registered in _task definitions_ **before** they can be launched.

Tasks can be executed as [Standalone tasks] or [services].<br/>
Whatever the _launch type_:

1. On launch, a task is created and moved to the `PROVISIONING` state.<br/>
   While in this state, ECS needs to find compute capacity for the task and neither the task nor its containers exist.
1. ECS selects the appropriate compute capacity for the task based on its launch type or capacity provider
   configuration.

   Tasks will fail immediately should there be not enough compute capacity for the task in the launch type or capacity
   provider.

   When using a capacity provider with managed scaling enabled, tasks that can't be started due to a lack of compute
   capacity are kept in the `PROVISIONING` state while ECS provisions the necessary attachments.
1. ECS uses the container agent to pull the task's container images.
1. ECS starts the task's containers.
1. ECS moves the task into the `RUNNING` state.

### EC2 launch type

Starts tasks onto _registered_ EC2 instances.

Instances can be registered:

- Manually.
- Automatically, by using the _cluster auto scaling_ feature to dynamically scale the cluster's compute capacity.

### Fargate launch type

Starts tasks on dedicated, managed EC2 instances that are **not** reachable by the users.

Instances are automatically provisioned, configured, and registered to scale one's cluster capacity.<br/>
The service takes care itself of all the infrastructure management for the tasks.

### Standalone tasks

Refer [Amazon ECS standalone tasks].

Meant to perform some work, then stop similarly to batch processes.

Can be executed on schedules using the EventBridge Scheduler.

### Services

Refer [Amazon ECS services].

Execute and maintain a defined number of instances of the same task simultaneously in a cluster.

Tasks executed in services are meant to stay active until decommissioned, much like web services.<br/>
Should any of such tasks fail or stops, the service scheduler will launch another instance of the same task to replace
the one that failed.

One can optionally expose services behind a load balancer to distribute traffic across the tasks that the service
manages.

The service scheduler will replace unhealthy tasks should a container health check or a load balancer target group
health check fail.<br/>
This depends on the `maximumPercent` and `desiredCount` parameters in the service's definition.

If a task is marked unhealthy, the service scheduler will first start a replacement task. Then:

- If the replacement task is `HEALTHY`, the service scheduler stops the unhealthy task.
- If the replacement task is also `UNHEALTHY`, the scheduler will stop either the unhealthy replacement task or the
  existing unhealthy task to get the total task count equal to the `desiredCount` value.

Should the `maximumPercent` parameter limit the scheduler from starting a replacement task first, the scheduler will:

- Stop unhealthy tasks one at a time at random in order to free up capacity.
- Start a replacement task.

The start and stop process continues until all unhealthy tasks are replaced with healthy tasks.<br/>
Should the total task count still exceed `desiredCount` once all unhealthy tasks have been replaced and only healthy
tasks are running, healthy tasks are stopped at random until the total task count equals `desiredCount`.

The service scheduler includes logic that throttles how often tasks are restarted if they repeatedly fail to start.<br/>
If a task is stopped without having entered the `RUNNING` state, the service scheduler starts to slow down the launch
attempts and sends out a service event message.<br/>
This prevents unnecessary resources from being used for failed tasks before one can resolve the issue.<br/>
On service update, the service scheduler resumes normal scheduling behavior.

Available service scheduler strategies:

- `REPLICA`: places and maintains the desired number of tasks across one's cluster.<br/>
  By default, tasks are spread across Availability Zones. Use task placement strategies and constraints to customize
  task placement decisions.
- `DAEMON`: deploys **exactly** one task on **each** active container instance meeting all of the task placement
  constraints for the task.<br/>
  There is no need to specify a desired number of tasks, a task placement strategy, or use Service Auto Scaling policies
  when using this strategy.

  Fargate does **not** support the `DAEMON` scheduling strategy.

## Capacity providers

Refer [Capacity providers].

Clusters can contain a mix of tasks that are hosted on Fargate, Amazon EC2 instances, or external instances.<br/>
Tasks can run on Fargate or EC2 infrastructure as a launch type or a capacity provider strategy.<br/>
Capacity providers manage the scaling of infrastructure for tasks in one's clusters.

Each cluster can have one or more _capacity providers_, and an optional _capacity provider strategy_.

The capacity provider strategy determines how tasks are spread across a cluster's capacity providers.<br/>
One can assign a **default** capacity provider strategy to a cluster. This strategy **only** applies when one does not
specify a launch type nor a capacity provider strategy for a task or service. If either of these parameters is provided,
the default strategy is ignored.<br/>
When running a standalone task or creating a service, one can either use the cluster's default capacity provider
strategy or provide one that overrides the default.

One must associate a capacity provider with a cluster **before** associating it with a capacity provider strategy.<br/>
Strategies allow to specify a maximum of 20 capacity providers.

Strategies' weight value defaults to `1` when creating it from the Console, and to `0` if using the API or CLI.

To run tasks on Fargate, one only needs to associate one or more of the pre-defined Fargate-specific capacity providers
with the cluster. This takes away the need to create or manage that cluster's capacity.

Clusters _can_ contain a mix of Fargate and Auto Scaling group capacity providers. However, a capacity provider strategy
can only contain either Fargate or Auto Scaling group capacity providers, but **not both**.

One **cannot** update a service that is using an Auto Scaling Group capacity provider to use a Fargate one, and
vice versa.

When multiple capacity providers are specified within a strategy, at least one of the providers **must** have a weight
value greater than zero.<br/>
Capacity providers with a weight of zero are **not** used to run tasks. Should all specified providers in a strategy
have the same weight of zero, any RunTask or CreateService actions using that strategy will fail.

In strategies, only **one** capacity provider can have a defined `base` value. If no base value is specified for a
provider, it defaults to zero.

A cluster can contain a mix of services and standalone tasks that use both capacity providers and launch types.<br/>
Services _can_ be updated to use a capacity provider strategy instead of a launch type, but one will need to force a new
deployment to do so.

### EC2 capacity providers

Refer [Amazon ECS capacity providers for the EC2 launch type].

When using EC2 instances for capacity, one really uses Auto Scaling groups to manage the EC2 instances.<br/>
Auto Scaling helps ensure that one has the correct number of EC2 instances available to handle the application's load.

### Fargate for ECS

Refer [AWS Fargate Spot Now Generally Available] and [Amazon ECS clusters for Fargate].

ECS can run tasks on the `Fargate` and `Fargate Spot` capacity when they are associated with a cluster.

Fargate Spot is intended for **interruption tolerant** tasks.<br/>
runs tasks on spare compute capacity. This makes it cost less the normal Fargate price, but comes with the ability for
AWS to interrupt tasks when it needs capacity back.

During periods of extremely high demand, Fargate Spot capacity might be unavailable.<br/>
When this happens, ECS services retry launching tasks until the required capacity becomes available.

ECS sends **a two-minute warning** before Spot tasks are stopped due to a Spot interruption. This warning is sent as a
task state change event to EventBridge and as a SIGTERM signal to the running task.

<details style='padding: 0 0 1rem 1rem'>

```json
{
  "version": "0",
  "id": "9bcdac79-b31f-4d3d-9410-fbd727c29fab",
  "detail-type": "ECS Task State Change",
  "source": "aws.ecs",
  "account": "111122223333",
  "resources": [
    "arn:aws:ecs:us-east-1:111122223333:task/b99d40b3-5176-4f71-9a52-9dbd6f1cebef"
  ],
  "detail": {
    "clusterArn": "arn:aws:ecs:us-east-1:111122223333:cluster/default",
    "createdAt": "2016-12-06T16:41:05.702Z",
    "desiredStatus": "STOPPED",
    "lastStatus": "RUNNING",
    "stoppedReason": "Your Spot Task was interrupted.",
    "stopCode": "SpotInterruption",
    "taskArn": "arn:aws:ecs:us-east-1:111122223333:task/b99d40b3-5176-4f71-9a52-9dbd6fEXAMPLE",
    ...
  }
}
```

</details>

When Spot tasks are terminated, the service scheduler receives the interruption signal and attempts to launch additional
tasks on Fargate Spot if such capacity is available, possibly from a different Availability Zone.

Fargate will **not** replace Spot capacity with on-demand capacity.

Ensure containers exit gracefully before the task stops by configuring the following:

- Specify a `stopTimeout` value of 120 seconds or less in the container definition that the task is using.<br/>
  The default value is 30 seconds. A higher value will provide more time between the moment that the task's state change
  event is received and the point in time when the container is forcefully stopped.
- Make sure the `SIGTERM` signal is caught from within the container and triggers any cleanup actions.<br/>
  Not processing this signal results in the task receiving a `SIGKILL` signal after the configured `stopTimeout` value,
  which may result in data loss or corruption.

## Resource constraints

ECS uses the CPU period and the CPU quota to control the task's CPU **hard** limits **as a whole**.<br/>
When specifying CPU values in task definitions, ECS translates that value to the CPU period and CPU quota settings that
apply to the cgroup running **all** the containers in the task.

The CPU quota controls the amount of CPU time granted to a cgroup during a given CPU period. Both settings are expressed
in terms of microseconds.<br/>
When the CPU quota equals the CPU period, a cgroup can execute up to 100% on one vCPU (or any other fraction that totals
to 100% for multiple vCPUs). The CPU quota has a maximum of 1000000us, and the CPU period has a minimum of 1ms.
Use these values to set the limits for the tasks' CPU count.

When changing the CPU period with**out** changing the CPU quota, the task will have different effective limits than what
is specified in the task definition.

The 100ms period allows for vCPUs ranging from 0.125 to 10.

Task-level CPU and memory parameters are ignored for Windows containers.

The `cpu` value must be expressed in _CPU units_ or _vCPUs_.<br/>
_vCPUs_ are converted to _CPU units_ when task definitions are registered.

The `memory` value can be expressed in _MiB_ or _GB_.<br/>
_GB_s are converted to _MiB_ when tasks definitions are registered.

These fields are optional for tasks hosted on EC2.<br/>
Such tasks support CPU values between 0.25 and 10 vCPUs. these fields are optional

Task definitions specifying `FARGATE` as value for the `requiresCompatibilities` attribute, **even if they also specify
the `EC2` value**, **are required** to set both settings **and** to set them to one of the couples specified in the
table.<br/>
Fargate task definitions support **only** those [specific values for tasks' CPU and memory][fargate tasks sizes].

| CPU units | vCPUs | Memory values                               | Supported OSes | Notes                            |
| --------- | ----- | ------------------------------------------- | -------------- | -------------------------------- |
| 256       | .25   | 512 MiB, 1 GB, or 2 GB                      | Linux          |                                  |
| 512       | .5    | Between 1 GB and 4 GB in 1 GB increments    | Linux          |                                  |
| 1024      | 1     | Between 2 GB and 8 GB in 1 GB increments    | Linux, Windows |                                  |
| 2048      | 2     | Between 4 GB and 16 GB in 1 GB increments   | Linux, Windows |                                  |
| 4096      | 4     | Between 8 GB and 30 GB in 1 GB increments   | Linux, Windows |                                  |
| 8192      | 8     | Between 16 GB and 60 GB in 4 GB increments  | Linux          | Requires Linux platform >= 1.4.0 |
| 16384     | 16    | Between 32 GB and 120 GB in 8 GB increments | Linux          | Requires Linux platform >= 1.4.0 |

The task's settings are **separate** from the CPU and memory values that can be defined at the container definition
level.<br/>
Should both a container-level `memory` and `memoryReservation` value be set, the `memory` value **must be higher** than
the `memoryReservation` value.<br/>
If specifying `memoryReservation`, that value is guaranteed to the container and subtracted from the available memory
resources for the container instance that the container is placed on. Otherwise, the value of `memory` is used.

## Environment variables

Refer [Amazon ECS environment variables].

ECS sets default environment variables for any task it runs.

<details>

```sh
$ aws ecs list-tasks --cluster 'devel' --service-name 'prometheus' --query 'taskArns' --output 'text' \
  | xargs -I '%%' aws ecs execute-command --cluster 'devel' --task '%%' --container 'prometheus' \
      --interactive --command 'printenv'

The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.


Starting session with SessionId: ecs-execute-command-abcdefghijklmnopqrstuvwxyz
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
HOSTNAME=ip-172-31-10-103.eu-west-1.compute.internal
AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=/v2/credentials/abcdefgh-1234-abcd-9876-abcdefgh0123
AWS_DEFAULT_REGION=eu-west-1
AWS_EXECUTION_ENV=AWS_ECS_FARGATE
AWS_REGION=eu-west-1
ECS_AGENT_URI=http://169.254.170.2/api/abcdef0123456789abcdef0123456789-1111111111
ECS_CONTAINER_METADATA_URI=http://169.254.170.2/v3/abcdef0123456789abcdef0123456789-1111111111
ECS_CONTAINER_METADATA_URI_V4=http://169.254.170.2/v4/abcdef0123456789abcdef0123456789-1111111111
HOME=/root
TERM=xterm-256color
LANG=C.UTF-8


Exiting session with sessionId: ecs-execute-command-abcdefghijklmnopqrstuvwxyz.
```

</details>

## Storage

Refer [Storage options for Amazon ECS tasks].

| Volume type      | Launch type support | OS support     | Persistence                                                                                                    | Use cases                                                                   |
| ---------------- | ------------------- | -------------- | -------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| [EBS volumes]    | EC2<br/>Fargate     | Linux          | _Can_ be persisted when used by a standalone task<br/>Ephemeral when attached to tasks maintained by a service | Transactional workloads                                                     |
| [EFS volumes]    | EC2<br/>Fargate     | Linux          | Persistent                                                                                                     | Data analytics<br/>Media processing<br/>Content management<br/>Web serving  |
| [Docker volumes] | EC2                 | Linux, Windows | Persistent                                                                                                     | Provide a location for data persistence<br/>Sharing data between containers |
| [Bind mounts]    | EC2<br/>Fargate     | Linux, Windows | Ephemeral                                                                                                      | Data analytics<br/>Media processing<br/>Content management<br/>Web serving  |

### EBS volumes

Refer [Use Amazon EBS volumes with Amazon ECS].

One can attach **at most one** EBS volume to each ECS task, and it **must be a new volume**.<br/>
One **cannot** attach existing EBS volume to tasks. However, one _can_ configure a new EBS volume at deployment to use
the snapshot of an existing volume as starting point.

Provisioning volumes from snapshots of EBS volumes that contains partitions is **not** supported.

EBS volumes can be configured at deployment **only** for services that use the _rolling update_ deployment type **and**
the _Replica_ scheduling strategy.

Containers in a task will be able to write to the mounted EBS volume **only** if the container runs as the `root` user.

ECS automatically adds the `AmazonECSCreated` and `AmazonECSManaged` reserved tags to attached volumes.<br/>
Should one remove these tags from the volumes, ECS won't be able to manage it anymore.

Volumes attached to tasks which are managed by a service are **not** preserved, and are **always** deleted upon task's
termination.

One **cannot** configure EBS volumes for attachment to ECS tasks running on AWS Outposts.

### EFS volumes

Refer [Use Amazon EFS volumes with Amazon ECS].

Allows tasks with access to the same EFS volumes to share persistent storage.

Tasks **must**:

- Reference the EFS volumes in the `volumes` attribute of their definition.
- Reference the defined volumes in the `mountPoints` attribute in the containers' specifications.

<details style="padding: 0 0 1em 1em;">

```json
{
    "volumes": [{
        "name": "myEfsVolume",
        "efsVolumeConfiguration": {
            "fileSystemId": "fs-1234",
            "rootDirectory": "/path/to/my/data",
            "transitEncryption": "ENABLED",
            "transitEncryptionPort": integer,
            "authorizationConfig": {
                "accessPointId": "fsap-1234",
                "iam": "ENABLED"
            }
        }
    }],
    "containerDefinitions": [{
        "name": "container-using-efs",
        "image": "amazonlinux:2",
        "entryPoint": [
            "sh",
            "-c"
        ],
        "command": [ "ls -la /mount/efs" ],
        "mountPoints": [{
            "sourceVolume": "myEfsVolume",
            "containerPath": "/mount/efs",
            "readOnly": true
        }]
    }]
}
```

</details>

EFS file systems are supported on

- EC2 nodes using ECS-optimized AMI version 20200319 with container agent version 1.38.0.
- Fargate since platform version 1.4.0 or later (Linux).

**Not** supported on external instances.

### Docker volumes

Refer [Use Docker volumes with Amazon ECS].

TODO

### Bind mounts

Refer [Use bind mounts with Amazon ECS].

TODO

## Execute commands in tasks' containers

Refer [Using Amazon ECS Exec to access your containers on AWS Fargate and Amazon EC2],
[A Step-by-Step Guide to Enabling Amazon ECS Exec],
[`aws ecs execute-command` results in `TargetNotConnectedException` `The execute command failed due to an internal error`]
and [Amazon ECS Exec Checker].

Leverage ECS Exec, which in turn leverages SSM to create a secure channel between one's device and the target container.
It does so by bind-mounting the necessary SSM agent binaries into the container while the ECS (or Fargate) agent starts
the SSM core agent inside the container.<br/>
The agent, when invoked, calls SSM to create the secure channel. In order to do so, the container's ECS task must have
the proper IAM privileges for the SSM core agent to call the SSM service.

The SSM agent does **not** run as a separate container sidecar, but as an additional process **inside** the application
container.<br/>
Refer [ECS Execute-Command proposal] for details.

Whe whole procedure is transparent and does **not** compel requirements changes in the container's content.

Requirements:

- The required SSM components must be available on the EC2 instances hosting the container.
  Amazon's ECS optimized AMI and Fargate 1.4.0+ include their latest version already.
- The container's image must have `script` and `cat` installed.<br/>
  Required in order to have command logs uploaded correctly to S3 and/or CloudWatch.
- The task's role (**not** the Task's _execution_ role) must have specific permissions assigned.

  <details style="padding-bottom: 1em;">
    <summary>Policy example</summary>

  ```json
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Sid": "RequiredSSMPermissions",
              "Effect": "Allow",
              "Action": [
                  "ssmmessages:CreateControlChannel",
                  "ssmmessages:CreateDataChannel",
                  "ssmmessages:OpenControlChannel",
                  "ssmmessages:OpenDataChannel"
              ],
              "Resource": "*"
          },
          {
              "Sid": "RequiredGlobalCloudWatchPermissions",
              "Effect": "Allow",
              "Action": "logs:DescribeLogGroups",
              "Resource": "*"
          },
          {
              "Sid": "RequiredSpecificCloudWatchPermissions",
              "Effect": "Allow",
              "Action": [
                  "logs:CreateLogStream",
                  "logs:DescribeLogStreams",
                  "logs:PutLogEvents"
              ],
              "Resource": [
                  "arn:aws:logs:eu-west-1:012345678901:log-group:log-group-name",
                  "arn:aws:logs:eu-west-1:012345678901:log-group:log-group-name:log-stream:log-stream-name"
              ]
          },
          {
              "Sid": "OptionalS3PermissionsIfSSMRecordsLogsInBuckets",
              "Effect": "Allow",
              "Action": [
                  "s3:GetEncryptionConfiguration",
                  "s3:PutObject"
              ],
              "Resource": [
                  "arn:aws:s3:::ecs-exec-bucket",
                  "arn:aws:s3:::ecs-exec-bucket/session-logs/*"
              ]
          },
          {
              "Sid": "OptionalKMSPermissionsIfSSMRecordsLogsInEncryptedBuckets",
              "Effect": "Allow",
              "Action": [
                  "kms:Decrypt",
                  "kms:GenerateDataKey"
              ],
              "Resource": "arn:aws:kms:eu-west-1:012345678901:key/abcdef01-2345-6789-abcd-ef0123456789"
          },
      ]
  }
  ```

  </details>

- The service or the `run-task` command that start the task **must have the `enable-execute-command` set to `true`**.

  <details style="padding-bottom: 1em;">
    <summary>Examples</summary>

  ```sh
  aws ecs run-task … --enable-execute-command
  aws ecs update-service --cluster 'stg' --service 'grafana' --enable-execute-command --force-new-deployment
  ```

  ```ts
  new aws.ecs.Service(
    'whatever',
    { enableExecuteCommand: true,  …, },
  );
  ```

  </details>

- **Users** initiating the execution:

  - Must [install the Session Manager plugin for the AWS CLI].
  - Must be allowed the `ecs:ExecuteCommand` action on the ECS cluster.

    <details style="padding-bottom: 1em;">
      <summary>Policy example</summary>

    ```json
    {
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Action": "ecs:ExecuteCommand",
            "Resource": "arn:aws:ecs:eu-west-1:012345678901:cluster/devel",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/application": "someApp",
                    "aws:ResourceTag/component": [
                        "someComponent",
                        "someOtherComponent"
                    ],
                    "ecs:container-name": "nginx"
                }
            }
        }]
    }
    ```

    </details>

Procedure:

1. Confirm that the task's `ExecuteCommandAgent` status is `RUNNING` and the `enableExecuteCommand` attribute is set to
   `true`.

   <details style="padding-bottom: 1em;">
    <summary>Example</summary>

   ```sh
   aws ecs describe-tasks --cluster 'devel' --tasks 'ef6260ed8aab49cf926667ab0c52c313' --output 'yaml' \
     --query 'tasks[0] | {
       "managedAgents": containers[].managedAgents[?@.name==`ExecuteCommandAgent`][],
       "enableExecuteCommand": enableExecuteCommand
     }'

   aws ecs list-tasks --cluster 'devel' --service-name 'mimir' --query 'taskArns' --output 'text' \
   | xargs \
       aws ecs describe-tasks --cluster 'devel' \
         --output 'yaml' --query 'tasks[0] | {
           "managedAgents": containers[].managedAgents[?@.name==`ExecuteCommandAgent`][],
           "enableExecuteCommand": enableExecuteCommand
         }' \
         --tasks
   ```

   ```yaml
   enableExecuteCommand: true
   managedAgents:
   - lastStartedAt: '2025-01-28T22:16:59.370000+01:00'
     lastStatus: RUNNING
     name: ExecuteCommandAgent
   ```

   </details>

1. Execute the command.

   <details style="padding-bottom: 1em;">
    <summary>Example</summary>

   ```sh
   aws ecs execute-command --interactive --command 'df -h' \
     --cluster 'devel' --task 'ef6260ed8aab49cf926667ab0c52c313' --container 'nginx'
   ```

   ```plaintext
   The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.

   Starting session with SessionId: ecs-execute-command-zobkrf3qrif9j962h9pecgnae8
   Filesystem      Size  Used Avail Use% Mounted on
   overlay          31G   12G   18G  40% /
   tmpfs            64M     0   64M   0% /dev
   shm             464M     0  464M   0% /dev/shm
   tmpfs           464M     0  464M   0% /sys/fs/cgroup
   /dev/nvme1n1     31G   12G   18G  40% /etc/hosts
   /dev/nvme0n1p1  4.9G  2.1G  2.8G  43% /managed-agents/execute-command
   tmpfs           464M     0  464M   0% /proc/acpi
   tmpfs           464M     0  464M   0% /sys/firmware

   Exiting session with sessionId: ecs-execute-command-zobkrf3qrif9j962h9pecgnae8.
   ```

   </details>

Should one's command invoke a shell, one will gain interactive access to the container.<br/>
In this case, **all commands and their outputs** inside the shell session **will** be logged to S3 and/or CloudWatch.
The shell invocation command and the user that invoked it will be logged in CloudTrail for auditing purposes as part of
the ECS ExecuteCommand API call.

Should one's command invoke a single command, **only the output** of the command will be logged to S3 and/or CloudWatch.
The command itself will still be logged in CloudTrail as part of the ECS ExecuteCommand API call.

Logging options are configured at the ECS cluster level.<br/>
The task's role **will** need to have IAM permissions to log the output to S3 and/or CloudWatch should the cluster be
configured for the above options. If the options are **not** configured, then the permissions are **not** required.

## Scale the number of tasks automatically

Refer [Automatically scale your Amazon ECS service].

Scaling**_out_** **increases** the number of tasks, scaling-**_in_** **decreases** it.

ECS sends metrics in **1-minute intervals** to CloudWatch.<br/>
Keep this in mind when tweaking the values for scaling.

### Target tracking

Refer [Target tracking scaling policies for Application Auto Scaling] and
[How target tracking scaling for Application Auto Scaling works].

The **only** available metrics for the integrated checks are currently:

- The service's **average** CPU utilization (`ECSServiceCPUUtilization`) for the last minute.
- The service's **average** memory utilization (`ECSServiceMemoryUtilization`) for the last minute.
- The service's Application Load Balancer's **average** requests count (`ALBRequestCountPerTarget`) for the last minute.

## Allow tasks to communicate with each other

Refer [How can I allow the tasks in my Amazon ECS services to communicate with each other?] and
[Interconnect Amazon ECS services].

Tasks in a cluster are **not** normally able to communicate with each other.<br/>
Use ECS Service Connect, ECS service discovery or VPC Lattice to allow that.

### ECS Service Connect

Refer [Use Service Connect to connect Amazon ECS services with short names].

ECS Service Connect provides ECS clusters with the configuration they need for service-to-service discovery,
connectivity, and traffic monitoring by building both service discovery and a service mesh in the clusters.

It provides:

- The complete configuration services need to join the mesh.
- A unified way to refer to services within namespaces that does **not** depend on the VPC's DNS configuration.
- Standardized metrics and logs to monitor all the applications.

The feature creates a virtual network of related services.<br/>
The same service configuration can be used across different namespaces to run independent yet identical sets of
applications.

When using Service Connect, ECS dynamically manages Service Connect endpoints for each task as they start and stop. It
does so by injecting the definition of a _sidecar_ proxy container **in services**. This does **not** change their task
definition.<br/>
Each task created for each registered service will end up running the sidecar proxy container in order, so that the task
is added to the mesh.

Injecting the proxy in the services and not in the task definitions allows for the same task definition to be reused to
run identical applications in different namespaces with different Service Connect configurations.<br/>
It also means that, since the proxy is **not** in the task definition, it **cannot** be configured by users.

Service Connect **only** interconnects **services** within the **same** namespace.

One can add one Service Connect configuration to new or existing services.<br/>
When that happens, ECS creates:

- A Service Connect endpoint in the namespace.
- A new deployment in the service that replaces the tasks that are currently running with ones equipped with the proxy.

Existing tasks and other applications can continue to connect to existing endpoints and external applications.<br/>
If a service using Service Connect adds tasks by scaling out, new connections from clients will be load balanced between
**all** of the running tasks. If the service is updated, new connections from clients will be load balanced only between
the **new** version of the tasks.

The list of endpoints in the namespace changes every time **any** service in that namespace is deployed.<br/>
Existing tasks, and replacement tasks, continue to behave the same as they did after the most recent deployment.<br/>
Existing tasks **cannot** resolve and connect to new endpoints. Only tasks with a Service Connect configuration in the
same namespace **and** that start running after this deployment can.

Applications can use short names and standard ports to connect to **services** in the same or other clusters.<br/>
This includes connecting across VPCs in the same AWS Region.

By default, the Service Connect proxy listens on the `containerPort` specified in the task definition's port
mapping.<br/>
The service's Security Group rules **must** allow incoming traffic to this port from the subnets where clients will run.

The proxy will consume some of the resources allocated to their task.<br/>
It is recommended:

- Adding at least 256 CPU units and 64 MiB of memory to the task's resources.
- \[If expecting tasks to receive more than 500 requests per second at their peak load] Increasing the sidecar's
  resources addition to at least 512 CPU units.
- \[If expecting to create more than 100 Service Connect services in the namespace, or 2000 tasks in total across all
  ECS services within the namespace], Adding 128 MiB extra of memory for the Service Connect proxy container.<br/>
  One **must** do this in **every** task definition that is used by **any** of the ECS services in the namespace.

It is recommended one sets the log configuration in the Service Connect configuration.

Proxy configuration:

- Tasks in a Service Connect endpoint are load balanced in a `round-robin` strategy.
- The proxy uses data about prior failed connections to avoid sending new connections to the tasks that had the failed
  connections for some time.<br/>
  At the time of writing, failing 5 or more connections in the last 30 seconds makes the proxy avoid that task for 30 to
  300 seconds.
- Connection that pass through the proxy and fail are retried, but **avoid** the host that failed the previous
  connection.<br/>
  This ensures that each connection through Service Connect doesn't fail for one-off reasons.
- Wait a maximum time for applications to respond.<br/>
  The default timeout value is 15 seconds, but it can be updated.

<details>
  <summary>Limitations</summary>

Service Connect does **not** support:

- ECS' `host` network mode.
- Windows containers.
- HTTP 1.0.
- Standalone tasks and any task created by other resources than services.
- Services using the `blue/green` or `external deployment` types.
- External container instance for ECS Anywhere.
- PPv2.
- Task definitions that set _container_ memory limits.
  It is required to set the _task_ memory limit though.

Tasks using the `bridge` network mode and Service Connect will **not** support the `hostname` container definition
parameter.

Each service can belong to only one namespace.

Service Connect can use any AWS Cloud Map namespace, as long as they are in the **same** Region **and** AWS account.

Service Connect does **not** delete namespaces when clusters are deleted.<br/>
One must delete namespaces in AWS Cloud Map themselves.

</details>

<details style="padding-bottom: 1rem">
  <summary>Requirements</summary>

- Tasks running in Fargate **must** use the Fargate Linux platform version 1.4.0 or higher.
- The ECS agent on container instances must be version 1.67.2 or higher.
- Container instances must run the ECS-optimized Amazon Linux 2023 AMI version `20230428` or later, or the ECS-optimized
  Amazon Linux 2 AMI version `2.0.20221115` or later.<br/>
  These versions equip the Service Connect agent in addition to the ECS container agent.
- Container instances must have the `ecs:Poll` permission assigned to them for resource
  `arn:aws:ecs:{{region}}:{{accountId}}:task-set/cluster/*`.<br/>
  If using the `ecsInstanceRole` or `AmazonEC2ContainerServiceforEC2Role` IAM roles, there is no need for additional
  permissions.
- Services **must** use the **rolling deployment** strategy, as it is the only one supported.
- Task definitions **must** set their task's memory limit.
- The task memory limit must be set to a number **greater** than the sum of the container memory limits.<br/>
  The CPU and memory in the task limits that aren't allocated in the container limits will be used by the
  Service Connect proxy container and other containers that don't set container limits.
- All endpoints must be **unique** within their namespace.
- All discovery names must be **unique** within their namespace.
- One **must** redeploy existing services before applications can resolve the new endpoints.<br/>
  New endpoints that are added to the namespace **after** the service's most recent deployment **will not** be added to
  the proxy configuration.
- Application Load Balancer traffic defaults to routing through the Service Connect agent in `awsvpc` network mode.<br/>
  If one wants non-service traffic to bypass the Service Connect agent, one will need to use the `ingressPortOverride`
  parameter in their Service Connect service configuration.

</details>

Procedure:

1. Configure the ECS cluster to use the desired AWS Cloud Map namespace.

   <details style="padding: 0 0 1rem 1rem">
     <summary>Simplified process</summary>

   Create the cluster with the desired name for the AWS Cloud Map namespace, and specify that name for the namespace
   when asked.<br/>
   ECS will create a new HTTP namespace with the necessary configuration.<br/>
   As reminder, Service Connect doesn't use or create DNS hosted zones in Amazon Route 53. FIXME: check this

   </details>

1. Configure port names in the server services' task definitions for all the port mappings that the services will expose
   in Service Connect.

   <details style="padding: 0 0 1rem 1rem">

   ```json
   containerDefinitions: [
       {
           "name": "postgres",
           "protocol": "tcp",
           "containerPort": 5432,
       },
       …
   ]
   ```

   </details>

1. Configure the server services to create Service Connect endpoints within the namespace.

   <details style="padding: 0 0 1rem 1rem">

   ```json
   "serviceConnectConfiguration": {
       "enabled": true,
       "namespace": "ecs-dev-cluster",
       "services": [{
           "portName": "postgres",
           "discoveryName": "postgres",
           "clientAliases": [{
               "port": 5432,
               "dnsName": "pgsql"
           }]
       }]
   },
   ```

   </details>

1. Deploy the services.<br/>
   This will create the endpoints AWS Cloud Map namespace used by the cluster.<br/>
   ECS also injects the Service Connect proxy container in each task.
1. Deploy the client applications as ECS services.<br/>
   ECS connects them to the Service Connect endpoints through the Service Connect proxy in each task.
1. Applications only use the proxy to connect to Service Connect endpoints.<br/>
   No additional configuration is required to use the proxy.
1. \[optionally] Monitor traffic through the Service Connect proxy in Amazon CloudWatch.

### ECS service discovery

Service discovery helps manage HTTP and DNS namespaces for ECS services.

ECS automatically registers and de-registers the list of launched tasks to AWS Cloud Map.<br/>
Cloud Map maintains DNS records that resolve to the internal IP addresses of one or more tasks from registered
services.<br/>
Other services in the **same** VPC can use such DNS records to send traffic directly to containers using their internal
IP addresses.

This approach provides low latency since traffic travels directly between the containers.

ECS service discovery is a good fit when using the `awsvpc` network mode, where:

- Each task is assigned its own, unique IP address.
- That IP address is an `A` record.
- Each service can have a unique security group assigned.

When using _bridged network_ mode, `A` records are no longer enough for service discovery and one **must** also use a
`SRV` DNS record. This is due to containers sharing the same IP address and having ports mapped randomly.<br/>
`SRV` records can keep track of both IP addresses and port numbers, but requires applications to be appropriately
configured.

Service discovery supports only the `A` and `SRV` DNS record types.<br/>
DNS records are automatically added or removed as tasks start or stop for ECS services.

Until ECS registers the tasks, Containers in them might complain about being unable to resolve the services they are
using.

DNS records have a TTL and it might happen that tasks died before this ended.<br/>
One **must** implement extra logic in one's applications, so that they can handle retries and deal with connection
failures when the records are not yet updated.

See also [Use service discovery to connect Amazon ECS services with DNS names].

Procedure:

1. Create the desired AWS Cloud Map namespace.
1. Create the desired Cloud Map service in the namespace.
1. Configure the ECS service offering acting as server to use the Cloud Map service.

   <details style="padding: 0 0 1rem 1rem">

   ```json
   "serviceRegistries": [{
       "registryArn": "arn:aws:servicediscovery:eu-west-1:012345678901:service/srv-uuf33b226vw93biy"
   }],
   ```

   </details>

NS lookup commands from within containers might fail, but they might still be able to resolve services registered in
CloudMap namespaces.

<details style="padding: 0 0 1rem 1rem">

```sh
$ aws ecs execute-command --cluster 'dev' \
    --task 'arn:aws:ecs:eu-west-1:012345678901:task/dev/abcdef0123456789abcdef0123456789' --container 'prometheus' \
    --interactive --command 'nslookup mimir.dev.ecs.internal'

The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.

Starting session with SessionId: ecs-execute-command-p3pkkrysjdptxa8iu3cz3kxnke
Server:   172.16.0.2
Address:  172.16.0.2:53

Non-authoritative answer:

$ aws ecs execute-command --cluster 'dev' \
    --task 'arn:aws:ecs:eu-west-1:012345678901:task/dev/abcdef0123456789abcdef0123456789' --container 'prometheus' \
    --interactive --command 'wget -SO- mimir.dev.ecs.local:8080/ready'

The Session Manager plugin was installed successfully. Use the AWS CLI to start a session.

Starting session with SessionId: ecs-execute-command-hjgyio7n6nf2o9h4qn6ht7lzri
Connecting to mimir.dev.ecs.local:8080 (172.16.88.99:8080)
  HTTP/1.1 200 OK
  Date: Thu, 08 May 2025 09:35:02 GMT
  Content-Type: text/plain
  Content-Length: 5
  Connection: close

saving to '/dev/stdout'
stdout               100% |********************************|     5  0:00:00 ETA
'/dev/stdout' saved

Exiting session with sessionId: ecs-execute-command-hjgyio7n6nf2o9h4qn6ht7lzri.
```

</details>

### VPC Lattice

Managed application networking service that customers can use to observe, secure, and monitor applications built across
AWS compute services, VPCs, and accounts without having to modify their code.

VPC Lattice technically replaces the need for Application Load Balancers by leveraging target groups themselves.<br/>
Target groups which are a collection of compute resources, and can refer EC2 instances, IP addresses, Lambda functions,
and Application Load Balancers.<br/>
Listeners are used to forward traffic to specified target groups when the conditions are met.<br/>
ECS also automatically replaces unhealthy tasks.

ECS tasks can be enabled **as IP targets** in VPC Lattice by associating their services with a VPC Lattice target
group.<br/>
ECS automatically registers tasks to the VPC Lattice target group when they are launched for registered services.

Deployments _might_ take longer when using VPC Lattice due to the extent of changes required.

See also [What is Amazon VPC Lattice?] and its [Amazon VPC Lattice pricing].

## Scrape metrics using Prometheus

Refer [Prometheus service discovery for AWS ECS] and [Scraping Prometheus metrics from applications running in AWS ECS].

> Prometheus is **not** currently capable to automatically discover ECS components like services or tasks.

Solutions:

- _Push_ the metrics instead by instrumenting the applications, or using tools like [AWS Distro for OpenTelemetry].
- Use a load balancer to access the service, and point Prometheus to the load balancer.

  Useful if needing to just monitor the availability of services.<br/>
  The load balancer will take care of monitoring the tasks in the target group.

  The scrape request needs to go through the load balancer.<br/>
  This **will** cost money.

- Target a lambda that returns a [308 Permanent Redirect] code with the current IP addresses of the requested tasks.
- Use dynamic service discovery mechanisms like [AWS Cloud Map][What Is AWS Cloud Map?].<br/>
  Refer [Metrics collection from Amazon ECS using Amazon Managed Service for Prometheus] and
  [aws-cloudmap-prometheus-sd].

## Send logs to a central location

### FireLens

Refer [Example Amazon ECS task definition: Route logs to FireLens], [Under the hood: FireLens for Amazon ECS Tasks] and
[Amazon ECS FireLens Examples].

Allows containers in ECS tasks to send logs to multiple destinations. Those can be AWS services (E.G. CloudWatch Logs
and OpenSearch), AWS partners (E.G. Splunk and Datadog), or any service supporting Fluent* output.

It uses Fluent Bit or Fluentd under the hood.<br/>
One can tweak their behaviour using according custom Fluent Bit or Fluentd configuration files from S3 or the container
image.

Requires a FireLens sidecar container to run alongside the main application's containers in order to process and forward
logs from them.<br/>
This log router sidecar container should be marked as `essential` in order to prevent silent log loss should it crash.

The log router's container image **can** be `amazon/aws-for-fluent-bit` if one wants to send data to an AWS service or
Partner.<br/>
It **must** be a custom image equipped with the required output plugins if not.

<details style='padding: 0 0 0 1rem'>
  <summary>Example: send logs to OpenSearch</summary>

```json
{
    "family": "nginx-to-opensearch",
    "networkMode": "awsvpc",
    "requiresCompatibilities": [ "FARGATE" ],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "arn:aws:iam::012345678901:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "nginx",
            "essential": true,
            "image": "012345678901.dkr.ecr.eu-west-1.amazonaws.com/docker-hub-cache/nginx:latest",
            "portMappings": [{
                "protocol": "tcp",
                "containerPort": 80
            }],
            "logConfiguration": {
                "logDriver": "awsfirelens",
                "options": {
                    "Name": "ElasticSearch",
                    "Host": "sweet-os-domain-of-mine.eu-west-1.es.amazonaws.com",
                    "Port": "443",
                    "AWS_Auth": "On",
                    "AWS_Region": "eu-west-1",
                    "Index": "nginx-logs",
                    "Type": "_doc",
                    "tls": "On"
                }
            }
        },
        {
          "name": "log_router",
          "essential": true,
          "image": "amazon/aws-for-fluent-bit:latest",
          "memoryReservation": 128,
          "firelensConfiguration": {
              "type": "fluentbit",
              "options": {
                  "enable-ecs-log-metadata": "true"
              }
          }
        }
    ]
}
```

</details>

<details style='padding: 0 0 1rem 1rem'>
  <summary>Example: send logs to Grafana Loki</summary>

```json
{
    "family": "nginx-to-loki",
    "networkMode": "awsvpc",
    "requiresCompatibilities": [ "FARGATE" ],
    "cpu": "256",
    "memory": "512",
    "executionRoleArn": "arn:aws:iam::012345678901:role/ecsTaskExecutionRole",
    "containerDefinitions": [
        {
            "name": "nginx",
            "essential": true,
            "image": "012345678901.dkr.ecr.eu-west-1.amazonaws.com/docker-hub-cache/nginx:latest",
            "portMappings": [{
                "protocol": "tcp",
                "containerPort": 80
            }],
            "logConfiguration": {
                "logDriver": "awsfirelens",
                "options": {
                  "Name": "loki",
                  "Host": "loki.example.org",
                  "Port": "3100",
                  "LogLevel": "info",
                  "Labels": "{job=\"nginx\", container=\"nginx\"}",
                  "tls": "off",
                  "remove_keys": "ecs_task_arn,ecs_cluster"
                }
            }
        },
        {
            "name": "log_router",
            "essential": true,
            "image": "012345678901.dkr.ecr.eu-west-1.amazonaws.com/custom/fluent-bit-with-loki-output-plugin:latest",
            "memoryReservation": 128,
            "firelensConfiguration": {
                "type": "fluentbit",
                "options": {
                    "enable-ecs-log-metadata": "true",
                    "config-file-type": "s3",
                    "config-file-value": "s3://custom-configs-bucket/fluent-bit/nginx-log-router.conf"
                }
            }
        }
    ]
}
```

</details>

### Fluent Bit or Fluentd

Refer [Centralized Container Logging with Fluent Bit].

Use the fluentd log driver in task definitions.<br/>
The fluentd-address value is specified as a secret option as it may be treated as sensitive data.

```json
"containerDefinitions": [{
    "logConfiguration": {
        "logDriver": "fluentd",
        "options": {
            "tag": "fluentd demo"
        },
        "secretOptions": [{
            "name": "fluentd-address",
            "valueFrom": "arn:aws:secretsmanager:region:aws_account_id:secret:fluentd-address-KnrBkD"
        }]
    },
    "entryPoint": [],
    "portMappings": [
        {
            "hostPort": 80,
            "protocol": "tcp",
            "containerPort": 80
        },
        {
            "hostPort": 24224,
            "protocol": "tcp",
            "containerPort": 24224
        }
    ]
}],
```

## Troubleshooting

### Invalid 'cpu' setting for task

Refer [Troubleshoot Amazon ECS task definition invalid CPU or memory errors] and [Resource constraints].

<details>
  <summary>Cause</summary>

One specified an invalid `cpu` or `memory` value for the task when registering a task definition using ECS's API or the
AWS CLI.

Should the task definition specify `FARGATE` as value for the `requiresCompatibilities` attribute, the resource values
must be one of the specific pairs supported by Fargate.

</details>

<details>
  <summary>Solution</summary>

Specify a supported value for the task CPU and memory in your task definition.

</details>

## Further readings

- [Amazon Web Services]
- [Amazon ECS task lifecycle]
- AWS' [CLI]
- [Troubleshoot Amazon ECS deployment issues]
- [Storage options for Amazon ECS tasks]
- [EBS]
- [EFS]
- [Amazon ECS Exec Checker]
- [ECS Execute-Command proposal]
- [What Is AWS Cloud Map?]
- [Centralized Container Logging with Fluent Bit]
- [Effective Logging Strategies with Amazon ECS and Fluentd]

### Sources

- [Identity and Access Management for Amazon Elastic Container Service]
- [Amazon ECS task role]
- [How Amazon Elastic Container Service works with IAM]
- [Troubleshoot Amazon ECS task definition invalid CPU or memory errors]
- [Use Amazon EBS volumes with Amazon ECS]
- [Attach EBS volume to AWS ECS Fargate]
- [Guide to Using Amazon EBS with Amazon ECS and AWS Fargate]
- [Amazon ECS task definition differences for the Fargate launch type]
- [How Amazon ECS manages CPU and memory resources]
- [Exposing multiple ports for an AWS ECS service]
- [Use Amazon EFS volumes with Amazon ECS]
- [Amazon ECS services]
- [Amazon ECS standalone tasks]
- [Using Amazon ECS Exec to access your containers on AWS Fargate and Amazon EC2]
- [A Step-by-Step Guide to Enabling Amazon ECS Exec]
- [`aws ecs execute-command` results in `TargetNotConnectedException` `The execute command failed due to an internal error`]
- [Prometheus service discovery for AWS ECS]
- [Metrics collection from Amazon ECS using Amazon Managed Service for Prometheus]
- [AWS Distro for OpenTelemetry]
- [aws-cloudmap-prometheus-sd]
- [Scraping Prometheus metrics from applications running in AWS ECS]
- [How can I allow the tasks in my Amazon ECS services to communicate with each other?]
- [Interconnect Amazon ECS services]
- [Amazon ECS Service Discovery]
- [AWS Fargate Pricing Explained]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[bind mounts]: #bind-mounts
[docker volumes]: #docker-volumes
[ebs volumes]: #ebs-volumes
[efs volumes]: #efs-volumes
[resource constraints]: #resource-constraints
[services]: #services
[standalone tasks]: #standalone-tasks

<!-- Knowledge base -->
[amazon web services]: README.md
[cli]: cli.md
[ebs]: ebs.md
[efs]: efs.md

<!-- Upstream -->
[Amazon ECS capacity providers for the EC2 launch type]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/asg-capacity-providers.html
[Amazon ECS clusters for Fargate]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-capacity-providers.html
[Amazon ECS environment variables]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-environment-variables.html
[amazon ecs exec checker]: https://github.com/aws-containers/amazon-ecs-exec-checker
[Amazon ECS FireLens Examples]: https://github.com/aws-samples/amazon-ecs-firelens-examples
[Amazon ECS Service Discovery]: https://aws.amazon.com/blogs/aws/amazon-ecs-service-discovery/
[amazon ecs services]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html
[amazon ecs standalone tasks]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/standalone-tasks.html
[amazon ecs task definition differences for the fargate launch type]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-tasks-services.html
[amazon ecs task lifecycle]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-lifecycle-explanation.html
[amazon ecs task role]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
[Amazon VPC Lattice pricing]: https://aws.amazon.com/vpc/lattice/pricing/
[Automatically scale your Amazon ECS service]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-auto-scaling.html
[AWS Distro for OpenTelemetry]: https://aws-otel.github.io/
[AWS Fargate Spot Now Generally Available]: https://aws.amazon.com/blogs/aws/aws-fargate-spot-now-generally-available/
[Capacity providers]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html#capacity-providers
[Centralized Container Logging with Fluent Bit]: https://aws.amazon.com/blogs/opensource/centralized-container-logging-fluent-bit/
[ecs execute-command proposal]: https://github.com/aws/containers-roadmap/issues/1050
[Example Amazon ECS task definition: Route logs to FireLens]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/firelens-taskdef.html
[fargate tasks sizes]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-tasks-services.html#fargate-tasks-size
[how amazon ecs manages cpu and memory resources]: https://aws.amazon.com/blogs/containers/how-amazon-ecs-manages-cpu-and-memory-resources/
[how amazon elastic container service works with iam]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security_iam_service-with-iam.html
[How can I allow the tasks in my Amazon ECS services to communicate with each other?]: https://repost.aws/knowledge-center/ecs-tasks-services-communication
[How target tracking scaling for Application Auto Scaling works]: https://docs.aws.amazon.com/autoscaling/application/userguide/target-tracking-scaling-policy-overview.html
[identity and access management for amazon elastic container service]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-iam.html
[install the session manager plugin for the aws cli]: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
[Interconnect Amazon ECS services]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/interconnecting-services.html
[Metrics collection from Amazon ECS using Amazon Managed Service for Prometheus]: https://aws.amazon.com/blogs/opensource/metrics-collection-from-amazon-ecs-using-amazon-managed-service-for-prometheus/
[storage options for amazon ecs tasks]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_data_volumes.html
[Target tracking scaling policies for Application Auto Scaling]: https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-target-tracking.html
[troubleshoot amazon ecs deployment issues]: https://docs.aws.amazon.com/codedeploy/latest/userguide/troubleshooting-ecs.html
[troubleshoot amazon ecs task definition invalid cpu or memory errors]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
[Under the hood: FireLens for Amazon ECS Tasks]: https://aws.amazon.com/blogs/containers/under-the-hood-firelens-for-amazon-ecs-tasks/
[use amazon ebs volumes with amazon ecs]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ebs-volumes.html
[use amazon efs volumes with amazon ecs]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/efs-volumes.html
[use bind mounts with amazon ecs]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bind-mounts.html
[use docker volumes with amazon ecs]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-volumes.html
[Use Service Connect to connect Amazon ECS services with short names]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html
[Use service discovery to connect Amazon ECS services with DNS names]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html
[using amazon ecs exec to access your containers on aws fargate and amazon ec2]: https://aws.amazon.com/blogs/containers/new-using-amazon-ecs-exec-access-your-containers-fargate-ec2/
[What is Amazon VPC Lattice?]: https://docs.aws.amazon.com/vpc-lattice/latest/ug/what-is-vpc-lattice.html
[What Is AWS Cloud Map?]: https://docs.aws.amazon.com/cloud-map/latest/dg/what-is-cloud-map.html

<!-- Others -->
[`aws ecs execute-command` results in `TargetNotConnectedException` `The execute command failed due to an internal error`]: https://stackoverflow.com/questions/69261159/aws-ecs-execute-command-results-in-targetnotconnectedexception-the-execute
[308 Permanent Redirect]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/308
[a step-by-step guide to enabling amazon ecs exec]: https://medium.com/@mariotolic/a-step-by-step-guide-to-enabling-amazon-ecs-exec-a88b05858709
[attach ebs volume to aws ecs fargate]: https://medium.com/@shujaatsscripts/attach-ebs-volume-to-aws-ecs-fargate-e23fea7bb1a7
[AWS Fargate Pricing Explained]: https://www.vantage.sh/blog/fargate-pricing
[aws-cloudmap-prometheus-sd]: https://github.com/awslabs/aws-cloudmap-prometheus-sd
[Effective Logging Strategies with Amazon ECS and Fluentd]: https://reintech.io/blog/effective-logging-strategies-amazon-ecs-fluent
[exposing multiple ports for an aws ecs service]: https://medium.com/@faisalsuhail1/exposing-multiple-ports-for-an-aws-ecs-service-64b9821c09e8
[guide to using amazon ebs with amazon ecs and aws fargate]: https://stackpioneers.com/2024/01/12/guide-to-using-amazon-ebs-with-amazon-ecs-and-aws-fargate/
[prometheus service discovery for aws ecs]: https://tomgregory.com/aws/prometheus-service-discovery-for-aws-ecs/
[Scraping Prometheus metrics from applications running in AWS ECS]: https://towardsaws.com/scraping-prometheus-metrics-from-aws-ecs-9c8d9a1ca1bd
