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
