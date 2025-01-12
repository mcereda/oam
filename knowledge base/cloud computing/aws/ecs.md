# Elastic Container Service

1. [TL;DR](#tldr)
1. [Resource constraints](#resource-constraints)
1. [Volumes](#volumes)
   1. [EBS](#ebs)
1. [Troubleshooting](#troubleshooting)
   1. [Invalid 'cpu' setting for task](#invalid-cpu-setting-for-task)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

The basic unit of a deployment is a _task_.<br/>
Tasks are a logical construct that model and run one or more containers. Containers **cannot** run by themselves on ECS.

ECS runs tasks as two different launch types:

- On EC2 instances that one owns, manages, and pays for.
- Using Fargate, technically a serverless environment for containers.

Unless otherwise restricted and capped, containers get access to all the CPU and memory capacity available on the host
running it.

Unless otherwise protected and guaranteed, all containers running on a given host share CPU, memory, and other resources
in the same way other processes running on that host share those resources.

By default, containers behave like other Linux processes with respect to access to resources like CPU and memory.

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

## Volumes

### EBS

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

## Troubleshooting

### Invalid 'cpu' setting for task

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

Refer [Troubleshoot Amazon ECS task definition invalid CPU or memory errors] and [Resource constraints].

## Further readings

- [Amazon Web Services]
- [Amazon ECS task lifecycle]
- AWS' [CLI]
- [Troubleshoot Amazon ECS deployment issues]

### Sources

- [Identity and Access Management for Amazon Elastic Container Service]
- [Amazon ECS task role]
- [How Amazon Elastic Container Service works with IAM]
- [Troubleshoot Amazon ECS task definition invalid CPU or memory errors]
- [Use Amazon EBS volumes with Amazon ECS]
- [Attach EBS volume to AWS ECS Fargate]
- [Guide to Using Amazon EBS with Amazon ECS and AWS Fargate]
- [How Amazon ECS manages CPU and memory resources]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[resource constraints]: #resource-constraints

<!-- Knowledge base -->
[amazon web services]: README.md
[cli]: cli.md

<!-- Upstream -->
[amazon ecs task lifecycle]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-lifecycle-explanation.html
[amazon ecs task role]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
[how amazon ecs manages cpu and memory resources]: https://aws.amazon.com/blogs/containers/how-amazon-ecs-manages-cpu-and-memory-resources/
[how amazon elastic container service works with iam]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security_iam_service-with-iam.html
[identity and access management for amazon elastic container service]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-iam.html
[troubleshoot amazon ecs deployment issues]: https://docs.aws.amazon.com/codedeploy/latest/userguide/troubleshooting-ecs.html
[troubleshoot amazon ecs task definition invalid cpu or memory errors]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
[use amazon ebs volumes with amazon ecs]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ebs-volumes.html

<!-- Others -->
[attach ebs volume to aws ecs fargate]: https://medium.com/@shujaatsscripts/attach-ebs-volume-to-aws-ecs-fargate-e23fea7bb1a7
[guide to using amazon ebs with amazon ecs and aws fargate]: https://stackpioneers.com/2024/01/12/guide-to-using-amazon-ebs-with-amazon-ecs-and-aws-fargate/
