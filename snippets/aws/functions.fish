#!/usr/bin/env fish

alias aws-caller-info 'aws sts get-caller-identity'
alias aws-ssm 'aws ssm start-session --target'
alias aws-whoami 'aws-caller-info'

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

function aws-iam-user-owning-accessKey
	aws iam list-users --no-cli-pager --query 'Users[].UserName' --output 'text' \
	| xargs -n1 \
	| shuf \
	| xargs -n1 -P (nproc) aws iam list-access-keys \
		--query "AccessKeyMetadata[?AccessKeyId=='$argv[1]'].UserName" \
		--output 'json' --user \
	| jq -rs 'flatten|first'
end

	aws iam list-users --no-cli-pager --query 'Users[].UserName' --output 'text' | xargs -n '1' | shuf \
	| xargs -n 1 -P (nproc) aws iam list-access-keys --output 'json' \
		--query "AccessKeyMetadata[?AccessKeyId=='$argv[1]'].UserName" --user \
	| jq -rs 'flatten|first'
end


alias aws-ec2-running-instanceIds "aws ec2 describe-instances --output 'text' \
	--filters 'Name=instance-state-name,Values=running' \
	--query 'Reservations[].Instances[0].InstanceId' \
| sed -E 's/\t+/\n/g'"
alias aws-ssm-gitlabAutoscalingManager-ita-b "aws ssm start-session --target ( \
	aws ec2 describe-instances --output text \
	--query 'Reservations[].Instances[0].InstanceId' \
	--filters \
		'Name=availability-zone,Values=eu-south-1b' \
		'Name=instance-state-name,Values=running' \
		'Name=tag:Name,Values=Gitlab Autoscaling Manager' \
)"
