#!fish

# Check the credentials are fine
aws sts get-caller-identity

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

function aws-ec2-instanceId-from-nameTag
	aws ec2 describe-instances --output text \
	--filters "Name=tag:Name,Values=$argv[1]" \
	--query 'Reservations[].Instances[0].InstanceId'
end

function aws-iam-role-arn-from-name
	aws iam list-roles --output 'text' \
		--query "Roles[?RoleName == '$argv[1]'].Arn"
end

alias aws-ec2-running-instanceIds "aws ec2 describe-instances --output 'text' \
	--filters 'Name=instance-state-name,Values=running' \
	--query 'Reservations[].Instances[0].InstanceId' \
| sed -E 's/\t+/\n/g'"
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

aws ecr delete-repository --repository-name 'bananaslug'

# Get Name and Description of all AMIs by Amazon for arm64 that are in the 'available' state
# and which name starts for 'al2023-ami-'
aws ec2 describe-images --output 'yaml' \
	--owners 'amazon' \
	--filters \
		'Name=architecture,Values=['arm64']' \
		'Name=state,Values=['available']' \
	--query '
		Images[]
		.{"Name":@.Name,"Description":@.Description}
	' \
| yq '.[]|select(.Name|test("^al2023-ami-"))' -

aws iam list-instance-profiles | grep -i 'ssm'

sudo ssm-cli get-diagnostics --output 'table'
