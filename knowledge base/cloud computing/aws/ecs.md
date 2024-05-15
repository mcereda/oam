# Elastic Container Service

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

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

## Further readings

- [Amazon Web Services]
- [Amazon ECS task lifecycle]
- AWS' [CLI]
- [Troubleshoot Amazon ECS deployment issues]

### Sources

- [Identity and Access Management for Amazon Elastic Container Service]
- [Amazon ECS task role]
- [How Amazon Elastic Container Service works with IAM]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[amazon web services]: README.md
[cli]: cli.md

<!-- Upstream -->
[amazon ecs task lifecycle]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-lifecycle-explanation.html
[amazon ecs task role]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
[how amazon elastic container service works with iam]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security_iam_service-with-iam.html
[identity and access management for amazon elastic container service]: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-iam.html
[troubleshoot amazon ecs deployment issues]: https://docs.aws.amazon.com/codedeploy/latest/userguide/troubleshooting-ecs.html
