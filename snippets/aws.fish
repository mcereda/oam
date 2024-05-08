#!fish

alias aws-caller-info 'aws sts get-caller-identity'
alias aws-ssm 'aws ssm start-session --target'

function aws-assume-role-by-name
	set current_caller (aws-caller-info --output json | jq -r '.UserId' -)
	aws-iam-role-arn-from-name "$argv[1]" \
	| xargs -I {} \
		aws sts assume-role \
			--role-arn "{}" \
			--role-session-name "$current_caller-as-$argv[1]-stsSession" \
	&& echo "Assumed role $argv[1]; Session name: '$current_caller-as-$argv[1]-stsSession'"
end

function aws-iam-role-arn-from-name
	aws iam list-roles --output 'text' \
		--query "Roles[?RoleName == '$argv[1]'].Arn"
end

alias aws-ssm-gitlabAutoscalingManager-ita-b "aws ec2 describe-instances --output text \
	--filters \
		'Name=availability-zone,Values=eu-south-1b' \
		'Name=instance-state-name,Values=running' \
		'Name=tag:Name,Values=Gitlab Autoscaling Manager' \
	--query 'Reservations[].Instances[0].InstanceId' \
| xargs -ot aws ssm start-session --target"

aws s3 rm 's3://bucket-name/prefix' --recursive --dry-run
aws s3 cp 's3://my-first-bucket/test.txt' 's3://my-other-bucket/'

aws ecs list-tasks --cluster 'testCluster' --family 'testService' --output 'text' --query 'taskArns' \
| xargs -p aws ecs wait tasks-running --cluster 'testCluster' --tasks
while [[ $$(aws ecs list-tasks --query 'taskArns' --output 'text' --cluster 'testCluster' --service-name 'testService') == "" ]]; do sleep 1; done

@aws ecs list-task-definitions --family-prefix 'testService' --output 'text' --query 'taskDefinitionArns' \
| xargs -pn '1' aws ecs deregister-task-definition --task-definition

aws ecs list-tasks --query 'taskArns' --output 'text' --cluster 'testCluster' --service-name 'testService' \
| tee \
| xargs -t aws ecs describe-tasks --query "tasks[].attachments[].details[?(name=='privateIPv4Address')].value" --output 'text' --cluster 'testCluster' --tasks \
| tee \
| xargs -I{} curl -fs "http://{}:8080"
