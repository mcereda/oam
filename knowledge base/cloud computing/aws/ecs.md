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
1. [Troubleshooting](#troubleshooting)
   1. [Invalid 'cpu' setting for task](#invalid-cpu-setting-for-task)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

_Tasks_ are the basic unit of deployment.<br/>
Their details are specified in _task definitions_.

_Standalone tasks_ are meant to perform some work, then stop much like batch processes.<br/>
_Services_ run and maintain a defined number of instances of the same task simultaneously, and are meant to stay active
much like web servers.

Tasks model and run one or more containers, much like Pods in Kubernetes.<br/>
Containers **cannot** run on ECS unless encapsulated in a task.

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
Fargate task definitions support **only** those specific values for tasks' CPU and memory.

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

TODO

### Bind mounts

TODO

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
[amazon ecs services]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html
[amazon ecs standalone tasks]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/standalone-tasks.html
[amazon ecs task definition differences for the fargate launch type]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-tasks-services.html
[amazon ecs task lifecycle]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-lifecycle-explanation.html
[amazon ecs task role]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
[how amazon ecs manages cpu and memory resources]: https://aws.amazon.com/blogs/containers/how-amazon-ecs-manages-cpu-and-memory-resources/
[how amazon elastic container service works with iam]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security_iam_service-with-iam.html
[identity and access management for amazon elastic container service]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-iam.html
[storage options for amazon ecs tasks]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_data_volumes.html
[troubleshoot amazon ecs deployment issues]: https://docs.aws.amazon.com/codedeploy/latest/userguide/troubleshooting-ecs.html
[troubleshoot amazon ecs task definition invalid cpu or memory errors]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
[use amazon ebs volumes with amazon ecs]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ebs-volumes.html
[use amazon efs volumes with amazon ecs]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/efs-volumes.html

<!-- Others -->
[attach ebs volume to aws ecs fargate]: https://medium.com/@shujaatsscripts/attach-ebs-volume-to-aws-ecs-fargate-e23fea7bb1a7
[exposing multiple ports for an aws ecs service]: https://medium.com/@faisalsuhail1/exposing-multiple-ports-for-an-aws-ecs-service-64b9821c09e8
[guide to using amazon ebs with amazon ecs and aws fargate]: https://stackpioneers.com/2024/01/12/guide-to-using-amazon-ebs-with-amazon-ecs-and-aws-fargate/
