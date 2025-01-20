#!/usr/bin/env fish

alias aws-caller-info 'aws sts get-caller-identity'
alias aws-ssm 'aws ssm start-session --target'
alias aws-whoami 'aws-caller-info'


function aws-alb-privateDnsName-from-name
	aws ec2 describe-network-interfaces --output 'text' \
		--query 'NetworkInterfaces[*].PrivateIpAddresses[*].PrivateDnsName' \
		--filters Name='description',Values="ELB app/$argv[1]/*"
end

function aws-alb-privateIps-from-name
	aws ec2 describe-network-interfaces --output 'text' \
		--query 'NetworkInterfaces[*].PrivateIpAddresses[*].PrivateIpAddress' \
		--filters Name='description',Values="ELB app/$argv[1]/*"
end


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

function aws-ec2-nameTag-from-instanceId
	aws ec2 describe-instances --output 'text' \
	--filters "Name=instance-id,Values=$argv[1]" \
	--query "Reservations[].Instances[0].Tags[?(@.Key=='Name')].Value"
end

function aws-ec2-tag-from-instanceId
	aws ec2 describe-instances --output 'text' \
	--filters "Name=instance-id,Values=$argv[1]" \
	--query "Reservations[].Instances[0].Tags[?(@.Key=='$argv[2]')].Value"
end

function aws-ec2-tags-from-instanceId
	aws ec2 describe-instances --output 'table' \
	--filters "Name=instance-id,Values=$argv[1]" \
	--query 'Reservations[].Instances[0].Tags[]'
end

function aws-ecs-tasks-from-clusterName-and-serviceName
	aws ecs list-tasks --cluster "$argv[1]" --output 'text' --query 'taskArns' \
	| xargs aws ecs describe-tasks --cluster "$argv[1]" \
		--query "tasks[?group.contains(@, '$argv[2]')]" --tasks
end

function aws-efs-mount-fs-locally-by-creation-token
	mkdir -p "/tmp/efs/$argv[1]"
	aws efs describe-file-systems --query 'FileSystems[].FileSystemId' --output 'text' --creation-token "$argv[1]" \
	| xargs aws efs describe-mount-targets --query 'MountTargets[].IpAddress|[0]' --output 'text' --file-system-id \
	| xargs -I '%%' mount -vt 'nfs' -o 'nfsvers=4,tcp,rwsize=1048576,hard,timeo=600,retrans=2,noresvport' "%%:/" "/tmp/efs/$argv[1]"
end

function aws-iam-roleArn-from-name
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
