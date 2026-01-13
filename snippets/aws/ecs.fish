#!/usr/bin/env fish

# List tasks given a service name
aws ecs list-tasks --query 'taskArns' --output 'text' --cluster 'testCluster' --service-name 'testService'

aws ecs list-tasks --output 'text' --query 'taskArns' --cluster 'testCluster' --family 'testService' \
| xargs -t aws ecs wait tasks-running --cluster 'testCluster' --tasks
while [[ $$( \
	aws ecs list-tasks --query 'taskArns' --output 'text' --cluster 'testCluster' --service-name 'testService' \
) == "" ]]; do sleep 1; done

aws ecs list-task-definitions --family-prefix 'testService' --output 'text' --query 'taskDefinitionArns' \
| xargs -pn '1' aws ecs deregister-task-definition --task-definition

aws ecs list-tasks --query 'taskArns' --output 'text' --cluster 'testCluster' --service-name 'testService' \
| tee \
| xargs -t -I '%%' \
	aws ecs describe-tasks --cluster 'testCluster' --tasks '%%' \
		--query "tasks[].attachments[].details[?(name=='privateIPv4Address')].value" --output 'text' \
| tee \
| xargs -I{} curl -fs "http://{}:8080"

# Describe tasks given a service name
aws ecs list-tasks --cluster 'testCluster' --output 'text' --query 'taskArns' \
| xargs aws ecs describe-tasks --cluster 'testCluster' --query "tasks[?group.contains(@, 'serviceName')]" --output 'yaml' --tasks

# Show information about services
aws ecs describe-services --cluster 'stg' --services 'grafana'

# Wait for services to be up and running
# Shortcut with polling for `aws ecs describe-services …
#   --query 'length(services[?!(length(deployments) == "1" && runningCount == desiredCount)]) == 0'`.
# Polls every 15 seconds until a successful state has been reached, or 40 checks failed.
# Exits with return code 255 after 40 failed checks.
aws ecs wait services-stable --cluster 'stg' --services 'grafana'

# Update services' attributes
aws ecs update-service --cluster 'stg' --service 'grafana' --enable-execute-command --force-new-deployment

# Scale services
aws ecs update-service --cluster 'stg' --service 'grafana' --desired-count '3'

# Check tasks' attributes
aws ecs describe-tasks --cluster 'staging' --tasks 'ef6260ed8aab49cf926667ab0c52c313' --output 'yaml' \
	--query 'tasks[0] | {
		"managedAgents": containers[].managedAgents[?@.name==`ExecuteCommandAgent`][],
		"enableExecuteCommand": enableExecuteCommand
	}'
aws ecs list-tasks --cluster 'staging' --service-name 'mimir' --query 'taskArns' --output 'text' \
| xargs aws ecs describe-tasks --cluster 'staging' \
	--output 'yaml' --query 'tasks[0] | {
		"managedAgents": containers[].managedAgents[?@.name==`ExecuteCommandAgent`][],
		"enableExecuteCommand": enableExecuteCommand
    }' \
    --tasks

# Execute commands in tasks
aws ecs execute-command --cluster 'dev' --task '5724249c0b734923841c82f54464e12b' --container 'debug' \
	--interactive --command 'bash'
aws ecs execute-command --cluster 'staging' --task 'e242654518cf42a7be13a8551e0b3c27' --container 'echo-server' \
	--interactive --command 'nc -vz 127.0.0.1 28080'
aws ecs execute-command --cluster 'staging' --task '0123456789abcdefghijklmnopqrstuv' --container 'pihole' \
	--interactive --command "dd if=/dev/zero of=/spaceHogger count=16048576 bs=1024"
# Execute commands in tasks given their service name
aws ecs list-tasks --cluster 'staging' --service-name 'prometheus' --query 'taskArns' --output 'text' \
| xargs -I '%%' aws ecs execute-command --cluster 'staging' --task '%%' --container 'prometheus' \
	--interactive --command 'nc -vz 127.0.0.1 9090'

# Stop tasks given a service name
aws ecs list-tasks --cluster 'staging' --service-name 'mimir' --query 'taskArns' --output 'text' \
| xargs aws ecs stop-task --cluster 'staging' --output 'text' --query 'task.lastStatus' --task

# Open the query page of a random task of a prometheus service running on ECS
aws ecs list-tasks --cluster 'dev' --service-name 'prometheus' --query 'taskArns' --output 'text' \
| xargs aws ecs describe-tasks --cluster 'dev' --query 'tasks[].attachments[].details[?@.name==`privateIPv4Address`].value' --output 'text' --tasks \
| shuf \
| head -n '1' \
| xargs -pI '%%' open 'http://%%:9090/query'

# List deployments
aws ecs list-service-deployments --cluster 'staging' --service 'mimir'

# Stop deployments
aws ecs stop-service-deployment \
	--service-deployment-arn 'arn:aws:ecs:eu-west-2:012345678901:service-deployment/staging/mimir/NCWGC2ZR-taawPAYrIaU5'
aws ecs stop-service-deployment --stop-type 'ROLLBACK' \
	--service-deployment-arn 'arn:aws:ecs:eu-west-2:012345678901:service-deployment/dev/grafana/Ge840vR55HHUwPAYrIaU5'

# Stop active deployments
aws ecs list-service-deployments --cluster 'staging' --service 'mimir' \
	--query "serviceDeployments[?@.status=='IN_PROGRESS'].serviceDeploymentArn" --output 'text' \
| xargs -pn 1 aws ecs stop-service-deployment --service-deployment-arn

# Get the image of specific containers.
aws ecs list-tasks --cluster 'someCluster' --service-name 'someService' --query 'taskArns[0]' --output 'text' \
| xargs -oI '%%' aws ecs describe-tasks --cluster 'someCluster' --task '%%' \
	--query 'tasks[].containers[?name==`someContainer`].image' --output 'text'
