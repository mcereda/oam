#!/usr/bin/env fish

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

# Show information about AMIs
aws ec2 describe-images --image-ids 'ami-01234567890abcdef'
aws ec2 describe-images --image-ids 'ami-01234567890abcdef' --query 'Images[].Description'


# Check instances are available for use with SSM
aws ssm get-connection-status --query "Status=='connected'" --output 'text' --target 'i-0915612ff82914822'
aws ssm describe-instance-associations-status --instance-id 'i-0f8b61c78622caed2'
# From the instance
sudo ssm-cli get-diagnostics --output 'table'

# Connect to instances if they are available
instance_id='i-08fc83ad07487d72f' \
&& eval $(aws ssm get-connection-status --target "$instance_id" --query "Status=='connected'" --output 'text') \
&& aws ssm start-session --target "$instance_id" \
|| (echo "instance ${instance_id} not available" >&2 && false)

# Send commands
aws ssm send-command --instance-ids 'i-08fc83ad07487d72f' --document-name 'AWS-RunShellScript' --parameters "commands='echo hallo'"
aws ssm wait command-executed --command-id 'e5f7ca0e-4d74-4316-84be-9ccaf3ae1f70' --instance-id 'i-08fc83ad07487d72f'
aws ssm get-command-invocation --command-id 'e5f7ca0e-4d74-4316-84be-9ccaf3ae1f70' --instance-id 'i-08fc83ad07487d72f'

# Run commands and get their output
set instance_id 'i-0915612f182914822' \
&& set command_id (aws ssm send-command --instance-ids "$instance_id" \
	--document-name 'AWS-RunShellScript' --parameters 'commands="echo hallo"' \
	--query 'Command.CommandId' --output 'text') \
&& aws ssm wait command-executed --command-id "$command_id" --instance-id "$instance_id" \
&& aws ssm get-command-invocation --command-id "$command_id" --instance-id "$instance_id" \
	--query '{"status": Status, "rc": ResponseCode, "stdout": StandardOutputContent, "stderr": StandardErrorContent}'


# Configure the CloudWatch agent
amazon-cloudwatch-agent-ctl -a 'status'
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a 'set-log-level' -l 'INFO'
amazon-cloudwatch-agent-ctl -a 'fetch-config' -m 'ec2' -s -c 'file:/opt/aws/amazon-cloudwatch-agent/bin/config.json'
tail -f '/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log'


# Delete unused volumes older than some date
aws ec2 describe-volumes --output 'text' --filters 'Name=status,Values=available' \
	--query "Volumes[?CreateTime<'2018-03-31'].VolumeId" \
| xargs -pn '1' aws ec2 delete-volume --volume-id

# Get volume IDs of EC2 instances
aws ec2 describe-instances --output 'text' \
	--filters 'Name=tag:Name,Values=Prometheus' 'Name=instance-state-name,Values=running' \
	--query 'Reservations[].Instances[0].BlockDeviceMappings[*].Ebs.VolumeId'

# Change volume type
aws ec2 modify-volume --volume-type 'gp3' --volume-id 'vol-0123456789abcdef0'

# Migrate gp2 volumes to gp3
aws ec2 describe-volumes --filters "Name=volume-type,Values=gp2" --query 'Volumes[].VolumeId' --output 'text' \
| xargs -pn '1' aws ec2 modify-volume --volume-type 'gp3' --volume-id

# Create snapshots of EBS volumes
aws ec2 create-snapshot --volume-id 'vol-0123456789abcdef0' --description 'Manual snapshot Pre-Update' \
	--tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=Prometheus},{Key=Team,Value=Infra}]' \

# Check state of snapshots
aws ec2 describe-snapshots --snapshot-ids 'snap-0123456789abcdef0' \
	--query 'Snapshots[].{"State": State,"Progress": Progress}' --output 'yaml'

# Wait for snapshots to finish.
aws ec2 wait snapshot-completed --snapshot-ids 'snap-0123456789abcdef0'

# Take snapshots of EC2 volumes and wait for them to finish
aws ec2 describe-instances --output 'text' \
	--filters 'Name=tag:Name,Values=Prometheus' 'Name=instance-state-name,Values=running' \
	--query 'Reservations[].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' \
| xargs -tn '1' aws ec2 create-snapshot --output 'text' --query 'SnapshotId' \
	--description 'Manual snapshot Pre-Update' \
	--tag-specifications 'ResourceType=snapshot,Tags=[{Key=Name,Value=Prometheus},{Key=Team,Value=Infra}]' \
	--volume-id \
| xargs -t aws ec2 wait snapshot-completed --snapshot-ids


# Retrieve the security credentials for an IAM role named 's3access' from instances
# IMDSv2
TOKEN=$(curl -X PUT 'http://169.254.169.254/latest/api/token' -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600') \
&& curl -H "X-aws-ec2-metadata-token: ${TOKEN}" 'http://169.254.169.254/latest/meta-data/iam/security-credentials/s3access'
# IMDSv1
curl 'http://169.254.169.254/latest/meta-data/iam/security-credentials/s3access'

# Find instance profiles
aws iam list-instance-profiles | grep -i 'ssm'


# Create instances
aws ec2 run-instances --instance-type 'c6a.xlarge' --image-id 'ami-0fcc0bef51bad3cb2' \
	--key-name 'mine' --security-group-ids 'sg-01234567890abcdef' --subnet-id 'subnet-0123456789abcdef0' \
	--no-associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=TEST}]' \
	--block-device-mappings 'Ebs={DeleteOnTermination=true,KmsKeyId=server-storage-key,Encrypted=true},DeviceName=xvda'

# Check instances status
aws ec2 describe-instances --instance-ids 'i-0123456789abcdef0' --output 'json' \
	--query 'Reservations[].Instances[].{"State":State,"StateReason":StateReason,"StateTransitionReason":StateTransitionReason}'

# Start stopped instances
# Requires the 'ec2:StartInstances' permission for the instances
# Also requires the 'kms:GenerateDataKeyWithoutPlaintext' and 'kms:CreateGrant' permissions for the keys used by the
#   instances, if any.
#   See https://docs.aws.amazon.com/ebs/latest/userguide/how-ebs-encryption-works.html#how-ebs-encryption-works-encrypted-snapshot
aws ec2 start-instances --instance-ids 'i-0123456789abcdef0'

# Stop started instances
# Requires the 'ec2:StopInstances' permission for the instances
aws ec2 stop-instances --instance-ids 'i-0123456789abcdef0'

# Terminate instances
aws ec2 terminate-instances --instance-ids 'i-0123456789abcdef0'

# Delete launch template versions
aws ec2 delete-launch-template-versions --launch-template-id 'lt-0123456789abcdef0' --versions '1' --dry-run
aws ec2 delete-launch-template-versions --launch-template-name 'GitLab Runners' --versions (seq 1 10) --dry-run
