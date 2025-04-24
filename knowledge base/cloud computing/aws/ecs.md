# Elastic Container Service

1. [TL;DR](#tldr)
1. [How it works](#how-it-works)
   1. [EC2 launch type](#ec2-launch-type)
   1. [Fargate launch type](#fargate-launch-type)
   1. [Standalone tasks](#standalone-tasks)
   1. [Services](#services)
1. [Resource constraints](#resource-constraints)
1. [Storage](#storage)
   1. [EBS volumes](#ebs-volumes)
   1. [EFS volumes](#efs-volumes)
   1. [Docker volumes](#docker-volumes)
   1. [Bind mounts](#bind-mounts)
1. [Execute commands in tasks' containers](#execute-commands-in-tasks-containers)
1. [Allow tasks to communicate with each other](#allow-tasks-to-communicate-with-each-other)
   1. [ECS Service Connect](#ecs-service-connect)
   1. [ECS service discovery](#ecs-service-discovery)
   1. [VPC Lattice](#vpc-lattice)
1. [Scrape metrics using Prometheus](#scrape-metrics-using-prometheus)
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
  Amazon's ECS optimized AMI and Fargate 1.4 include their latest version already.
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
              "Resource": "arn:aws:logs:eu-west-1:012345678901:log-group:/ecs/log-group-name:*"
          },
          {
              "Sid": "OptionalGlobalS3Permissions",
              "Effect": "Allow",
              "Action": "s3:GetEncryptionConfiguration",
              "Resource": "arn:aws:s3:::ecs-exec-bucket"
          },
          {
              "Sid": "OptionalSpecificS3Permissions",
              "Effect": "Allow",
              "Action": "s3:PutObject",
              "Resource": "arn:aws:s3:::ecs-exec-bucket/*"
          },
          {
              "Sid": "OptionalKMSPermissions",
              "Effect": "Allow",
              "Action": "kms:Decrypt",
              "Resource": "arn:aws:kms:eu-west-1:012345678901:key/abcdef01-2345-6789-abcd-ef0123456789"
          }
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
            "Resource": "arn:aws:ecs:eu-west-1:012345678901:cluster/staging",
            "Condition": {
                "StringEquals": {
                    "aws:ResourceTag/application": "appName",
                    "StringEquals": {
                        "ecs:container-name": "nginx"
                    }
                }
            },
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
   aws ecs describe-tasks --cluster 'staging' --tasks 'ef6260ed8aab49cf926667ab0c52c313' --output 'yaml' \
     --query 'tasks[0] | {
       "managedAgents": containers[].managedAgents[?@.name==`ExecuteCommandAgent`][],
       "enableExecuteCommand": enableExecuteCommand
     }'

   aws ecs list-tasks --cluster 'staging' --service-name 'mimir' --query 'taskArns' --output 'text' \
   | xargs \
       aws ecs describe-tasks --cluster 'Staging' \
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
     --cluster 'staging' --task 'ef6260ed8aab49cf926667ab0c52c313' --container 'nginx'
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

## Allow tasks to communicate with each other

Refer [How can I allow the tasks in my Amazon ECS services to communicate with each other?] and
[Interconnect Amazon ECS services].

Tasks in a cluster are **not** normally able to communicate with each other.<br/>
Use ECS Service Connect, ECS service discovery or VPC Lattice to allow that.

### ECS Service Connect

ECS Service Connect provides ECS clusters with the configuration they need for service discovery, connectivity, and
traffic monitoring.

Applications can use short names and standard ports to connect to **services** in the same or other clusters.<br/>
This includes connecting across VPCs in the same AWS Region.

When using Service Connect, ECS dynamically manages DNS entries for each task as they start and stop.<br/>
It does so by running an agent as sidecar container in each task that is configured to discover the names.

ECS manages the agent's container configuration in the service by itself. The agent's container is **not** available to
the tasks' definitions, so it **cannot** be configured.<br/>
ECS manages changes to this configuration in each service's deployment and ensures that all tasks in a deployment behave
in the same way.

Service Connect is **not** compatible with ECS' `host` network mode.

See also [Use Service Connect to connect Amazon ECS services with short names].

### ECS service discovery

Service discovery helps manage HTTP and DNS namespaces for ECS services.

ECS syncs the list of launched tasks to AWS Cloud Map.<br/>
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

DNS records have a TTL and it might happen that tasks died before this ended.<br/>
One **must** implement extra logic in one's applications, so that they can handle retries and deal with connection
failures when the records are not yet updated.

See also [Use service discovery to connect Amazon ECS services with DNS names].

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
- Use dynamic service discovery mechanisms like AWS Cloud Map.<br/>
  Refer [Metrics collection from Amazon ECS using Amazon Managed Service for Prometheus] and
  [aws-cloudmap-prometheus-sd].

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
[amazon ecs exec checker]: https://github.com/aws-containers/amazon-ecs-exec-checker
[amazon ecs services]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html
[amazon ecs standalone tasks]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/standalone-tasks.html
[amazon ecs task definition differences for the fargate launch type]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-tasks-services.html
[amazon ecs task lifecycle]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-lifecycle-explanation.html
[amazon ecs task role]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
[Amazon VPC Lattice pricing]: https://aws.amazon.com/vpc/lattice/pricing/
[AWS Distro for OpenTelemetry]: https://aws-otel.github.io/
[ecs execute-command proposal]: https://github.com/aws/containers-roadmap/issues/1050
[fargate tasks sizes]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-tasks-services.html#fargate-tasks-size
[how amazon ecs manages cpu and memory resources]: https://aws.amazon.com/blogs/containers/how-amazon-ecs-manages-cpu-and-memory-resources/
[how amazon elastic container service works with iam]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security_iam_service-with-iam.html
[How can I allow the tasks in my Amazon ECS services to communicate with each other?]: https://repost.aws/knowledge-center/ecs-tasks-services-communication
[identity and access management for amazon elastic container service]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-iam.html
[install the session manager plugin for the aws cli]: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
[Interconnect Amazon ECS services]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/interconnecting-services.html
[Metrics collection from Amazon ECS using Amazon Managed Service for Prometheus]: https://aws.amazon.com/blogs/opensource/metrics-collection-from-amazon-ecs-using-amazon-managed-service-for-prometheus/
[storage options for amazon ecs tasks]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_data_volumes.html
[troubleshoot amazon ecs deployment issues]: https://docs.aws.amazon.com/codedeploy/latest/userguide/troubleshooting-ecs.html
[troubleshoot amazon ecs task definition invalid cpu or memory errors]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
[use amazon ebs volumes with amazon ecs]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ebs-volumes.html
[use amazon efs volumes with amazon ecs]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/efs-volumes.html
[use bind mounts with amazon ecs]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/bind-mounts.html
[use docker volumes with amazon ecs]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-volumes.html
[Use Service Connect to connect Amazon ECS services with short names]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-connect.html
[Use service discovery to connect Amazon ECS services with DNS names]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html
[using amazon ecs exec to access your containers on aws fargate and amazon ec2]: https://aws.amazon.com/blogs/containers/new-using-amazon-ecs-exec-access-your-containers-fargate-ec2/
[What is Amazon VPC Lattice?]: https://docs.aws.amazon.com/vpc-lattice/latest/ug/what-is-vpc-lattice.html

<!-- Others -->
[`aws ecs execute-command` results in `TargetNotConnectedException` `The execute command failed due to an internal error`]: https://stackoverflow.com/questions/69261159/aws-ecs-execute-command-results-in-targetnotconnectedexception-the-execute
[308 Permanent Redirect]: https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status/308
[a step-by-step guide to enabling amazon ecs exec]: https://medium.com/@mariotolic/a-step-by-step-guide-to-enabling-amazon-ecs-exec-a88b05858709
[attach ebs volume to aws ecs fargate]: https://medium.com/@shujaatsscripts/attach-ebs-volume-to-aws-ecs-fargate-e23fea7bb1a7
[aws-cloudmap-prometheus-sd]: https://github.com/awslabs/aws-cloudmap-prometheus-sd
[exposing multiple ports for an aws ecs service]: https://medium.com/@faisalsuhail1/exposing-multiple-ports-for-an-aws-ecs-service-64b9821c09e8
[guide to using amazon ebs with amazon ecs and aws fargate]: https://stackpioneers.com/2024/01/12/guide-to-using-amazon-ebs-with-amazon-ecs-and-aws-fargate/
[prometheus service discovery for aws ecs]: https://tomgregory.com/aws/prometheus-service-discovery-for-aws-ecs/
[Scraping Prometheus metrics from applications running in AWS ECS]: https://towardsaws.com/scraping-prometheus-metrics-from-aws-ecs-9c8d9a1ca1bd
