#!/usr/bin/env fish


###
# Autoscaling Groups
# ------------------
###

aws autoscaling describe-auto-scaling-groups
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names 'ProductionServers'
aws autoscaling start-instance-refresh --auto-scaling-group-name 'ProductionServers'
aws autoscaling describe-instance-refreshes \
	--auto-scaling-group-name 'ProductionServers' --instance-refresh-ids '01234567-89ab-cdef-0123-456789abcdef'
aws autoscaling cancel-instance-refresh --auto-scaling-group-name 'ProductionServers'
aws autoscaling rollback-instance-refresh --auto-scaling-group-name 'ProductionServers'


###
# EC2
# ------------------
###

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

aws ssm describe-instance-associations-status --instance-id 'i-08fc83ad07487d72f'

# Send commands
aws ssm send-command --instance-ids 'i-08fc83ad07487d72f' --document-name 'AWS-RunShellScript' --parameters "commands='echo hallo'"
aws ssm wait command-executed --command-id 'e5f7ca0e-4d74-4316-84be-9ccaf3ae1f70' --instance-id 'i-08fc83ad07487d72f'
aws ssm get-command-invocation --command-id 'e5f7ca0e-4d74-4316-84be-9ccaf3ae1f70' --instance-id 'i-08fc83ad07487d72f'

# Run commands and get their output.
set instance_id 'i-0915612f182914822' \
&& set command_id (aws ssm send-command --instance-ids "$instance_id" \
	--document-name 'AWS-RunShellScript' --parameters 'commands="echo hallo"' \
	--query 'Command.CommandId' --output 'text') \
&& aws ssm wait command-executed --command-id "$command_id" --instance-id "$instance_id" \
&& aws ssm get-command-invocation --command-id "$command_id" --instance-id "$instance_id" \
	--query '{"status": Status, "rc": ResponseCode, "stdout": StandardOutputContent, "stderr": StandardErrorContent}'

aws ec2 describe-images --image-ids 'ami-01234567890abcdef'
aws ec2 describe-images --image-ids 'ami-01234567890abcdef' --query 'Images[].Description'

# Delete unused volumes older than some date
aws ec2 describe-volumes --output 'text' --filters 'Name=status,Values=available' \
	--query "Volumes[?CreateTime<'2018-03-31'].VolumeId" \
| xargs -pn '1' aws ec2 delete-volume --volume-id

# Get volume IDs of EC2 instances
aws ec2 describe-instances --output 'text' \
	--filters 'Name=tag:Name,Values=Prometheus' 'Name=instance-state-name,Values=running' \
	--query 'Reservations[].Instances[0].BlockDeviceMappings[*].Ebs.VolumeId'

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

watch -n '1' aws ec2 describe-instances --instance-ids 'i-0123456789abcdef0' --query 'Reservations[].Instances[].[State,StateTransitionReason]'

# Retrieve the security credentials for an IAM role named 's3access'
# IMDSv2
TOKEN=$(curl -X PUT 'http://169.254.169.254/latest/api/token' -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600') \
&& curl -H "X-aws-ec2-metadata-token: ${TOKEN}" 'http://169.254.169.254/latest/meta-data/iam/security-credentials/s3access'
# IMDSv1
curl 'http://169.254.169.254/latest/meta-data/iam/security-credentials/s3access'


###
# ECR
# ------------------
###

aws ecr describe-repositories
aws ecr create-repository --repository-name 'bananaslug' --registry-id '012345678901'
aws ecr delete-repository --repository-name 'bananaslug'

aws ecr get-login-password \
| docker login --username AWS --password-stdin '012345678901.dkr.ecr.eu-west-1.amazonaws.com'

aws ecr describe-pull-through-cache-rules --registry-id '012345678901'
aws ecr validate-pull-through-cache-rule --ecr-repository-prefix 'ecr-public'

docker pull '012345678901.dkr.ecr.eu-west-1.amazonaws.com/ecr-public/repository_name/image_name:tag'
docker pull '012345678901.dkr.ecr.eu-west-1.amazonaws.com/quay/repository_name/image_name:tag'

docker pull 'quay.io/argoproj/argocd:v2.10.0'
docker pull '012345678901.dkr.ecr.eu-west-1.amazonaws.com/me/argoproj/argocd:v2.10.0'

aws ecr create-pull-through-cache-rule --registry-id '012345678901' \
	--ecr-repository-prefix 'cache/docker-hub' \
	--upstream-registry 'docker-hub' --upstream-registry-url 'registry-1.docker.io' \
	--credential-arn "$(\
		aws secretsmanager describe-secret --secret-id 'ecr-pullthroughcache/docker-hub' --query 'ARN' --output 'text' \
	)"
aws ecr describe-pull-through-cache-rules --registry-id '012345678901' --ecr-repository-prefixes 'cache/docker-hub'

aws ecr list-images --registry-id '012345678901' --repository-name 'cache/docker-hub'


###
# ECS
# ------------------
###

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


###
# EKS
# ------------------
###

aws eks --region 'eu-west-1' update-kubeconfig --name 'oneForAll'
aws eks --region 'eu-west-1' update-kubeconfig --name 'oneForAll' --profile 'dev-user'
aws eks --region 'eu-west-1' update-kubeconfig --name 'oneForAll' --role-arn 'arn:aws:iam::012345678901:role/AssumedRole'

# Create OIDC providers for EKS clusters
# 1. Get the OIDC issuer ID for existing EKS clusters
set 'OIDC_ISSUER' (aws eks describe-cluster --name 'oneForAll' --query 'cluster.identity.oidc.issuer' --output 'text')
set 'OIDC_ID' (echo "$OIDC_ISSUER" | awk -F '/id/' '{print $2}')
# 2. Check they are present in the list of providers for the account
aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList' --output 'text' | grep "$OIDC_ID"
# 3. If the providers do not exist, create them
aws create create-open-id-connect-provider --url "$OIDC_ISSUER" --client-id-list 'sts.amazonaws.com'

aws iam list-roles --query "Roles[?RoleName=='EksEbsCsiDriverRole'].Arn"
aws iam list-attached-role-policies --role-name 'EksEbsCsiDriverRole' --query 'AttachedPolicies[].PolicyArn'
aws iam get-policy --policy-arn 'arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy' --query 'Policy'

aws eks describe-addon-versions --query 'sort(addons[].addonName)'
aws eks describe-addon-versions --addon-name 'eks-pod-identity-agent' --query 'addons[].addonVersions[]'
aws eks describe-addon-configuration --addon-name 'aws-ebs-csi-driver' --addon-version 'v1.32.0-eksbuild.1'
aws eks describe-addon-configuration --addon-name 'aws-ebs-csi-driver' --addon-version 'v1.32.0-eksbuild.1' \
	--query 'configurationSchema' --output 'text' | jq -sr


###
# ELB - Load Balancers
# ------------------
###

# Get load balancers IDs
aws elbv2 describe-load-balancers --names 'load-balancer-name' --query 'LoadBalancers[].LoadBalancerArn' --output 'text' \
| grep -o '[^/]*$'

# Get the private IP addresses of load balancers
aws ec2 describe-network-interfaces --output 'text' \
	--filters Name=description,Values='ELB app/application-load-balancer-name/application-load-balancer-id' \
	--query 'NetworkInterfaces[*].PrivateIpAddresses[*].PrivateIpAddress'
aws ec2 describe-network-interfaces --output 'text' \
	--filters Name=description,Values='ELB net/network-load-balancer-name/network-load-balancer-id' \
	--query 'NetworkInterfaces[*].PrivateIpAddresses[*].PrivateIpAddress'
aws ec2 describe-network-interfaces --output 'text' \
	--filters Name=description,Values='ELB classic-load-balancer-name' \
	--query 'NetworkInterfaces[*].PrivateIpAddresses[*].PrivateIpAddress'

# Get the public IP addresses of load balancers
aws ec2 describe-network-interfaces --output 'text' \
	--filters Name=description,Values='ELB app/application-load-balancer-name/application-load-balancer-id' \
	--query 'NetworkInterfaces[*].Association.PublicIp'
aws ec2 describe-network-interfaces --output 'text' \
	--filters Name=description,Values='ELB net/network-load-balancer-name/network-load-balancer-id' \
	--query 'NetworkInterfaces[*].Association.PublicIp'
aws ec2 describe-network-interfaces --output 'text' \
	--filters Name=description,Values='ELB classic-load-balancer-name' \
	--query 'NetworkInterfaces[*].Association.PublicIp'

###
# IAM
# ------------------
###

# Get all users' access keys
aws iam list-users --no-cli-pager --query 'Users[].UserName' --output 'text' \
| xargs -n1 aws iam list-access-keys --output 'json' --user

# Get the user owning a specific access key
aws iam list-users --no-cli-pager --query 'Users[].UserName' --output 'text' \
| xargs -n1 -P (nproc) aws iam list-access-keys \
	--query "AccessKeyMetadata[?AccessKeyId=='AKIA01234567890ABCDE'].UserName" --output 'json' --user \
| jq -rs 'flatten|first'

# Get details for access keys
# When no user is specified, it displays only keys for the current one
aws iam --no-cli-pager list-access-keys
aws iam --no-cli-pager list-access-keys --user-name 'mark'


###
# Image Builder
# ------------------
###

aws imagebuilder list-image-recipes
aws imagebuilder get-image-recipe \
	--image-recipe-arn 'arn:aws:imagebuilder:eu-west-1:012345678901:image-recipe/my-custom-image/1.0.12'


###
# KMS
# ------------------
###

aws kms get-key-policy --output 'text' --key-id '01234567-89ab-cdef-0123-456789abcdef'

aws kms create-key

aws kms get-public-key --key-id 'arn:aws:kms:eu-west-1:123456789012:key/d74f5077-811b-4447-af65-71f5f64f37d3' \
	--output text --query 'PublicKey' > 'RSAPublic.b64' \
&& base64 -d 'RSAPublic.b64' > 'RSAPublic.bin'

aws kms encrypt --key-id '01234567-89ab-cdef-0123-456789abcdef' --plaintext 'My Test String'
aws kms encrypt --key-id '01234567-89ab-cdef-0123-456789abcdef' --plaintext 'My Test String' \
	--query 'CiphertextBlob' --output 'text' \
| base64 --decode > 'ciphertext.dat'

aws kms decrypt --ciphertext-blob 'fileb://ciphertext.dat'
aws kms decrypt --ciphertext-blob 'fileb://ciphertext.dat' --query 'Plaintext' --output 'text' \
| base64 --decode
aws kms decrypt --key-id 'arn:aws:kms:eu-west-1:123456789012:key/d74f5077-811b-4447-af65-71f5f64f37d3' \
	--ciphertext-blob 'fileb://enc.key.bin' --encryption-algorithm 'RSAES_OAEP_SHA_256' \
	--output 'text' --query 'Plaintext' \
| base64 --decode > 'decryptedKey.bin'


###
# RDS
# ------------------
###

aws rds start-export-task \
	--export-task-identifier 'db-finalSnapshot-2024' \
	--source-arn 'arn:aws:rds:eu-west-1:012345678901:snapshot:db-prod-final-2024' \
	--s3-bucket-name 'backups' --s3-prefix 'rds' \
	--iam-role-arn 'arn:aws:iam::012345678901:role/CustomRdsS3Exporter' \
	--kms-key-id 'arn:aws:kms:eu-west-1:012345678901:key/abcdef01-2345-6789-abcd-ef0123456789'

# Max 5 running at any given time, RDS cannot queue
echo {1..5} | xargs -p -n '1' -I '{}' aws rds start-export-task …

aws rds describe-export-tasks --query 'ExportTasks[].WarningMessage' --output 'json'

aws rds restore-db-instance-to-point-in-time \
	--source-db-instance-identifier 'awx' --target-db-instance-identifier 'awx-pitred' \
	--restore-time '2024-07-31T09:29:40+00:00' \
	--allocated-storage '20'

aws rds restore-db-instance-from-db-snapshot \
	--db-instance-identifier 'awx-pitr-snapshot' \
	--db-snapshot-identifier 'rds:awx-2024-07-30-14-15'

aws rds delete-db-instance --skip-final-snapshot --db-instance-identifier 'awx'

aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15'
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15' \
	--query "Parameters[?ParameterName=='shared_preload_libraries']" --output 'table'
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15' \
	--query "Parameters[?ParameterName=='shared_preload_libraries'].ApplyMethod" --output 'text'
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15' --output 'json' --query "Parameters[?ApplyType!='dynamic']"


###
# Route53
# ------------------
###

aws route53 list-hosted-zones
aws route53 list-resource-record-sets --hosted-zone-id 'ABC012DEF345GH'


###
# S3
# ------------------
###

aws s3 rm 's3://bucket-name/prefix' --recursive --dry-run
aws s3 cp 's3://my-first-bucket/test.txt' 's3://my-other-bucket/'

aws s3api list-objects-v2 --bucket 'backup'
aws s3api list-objects-v2 --bucket 'backup' --query "Contents[?LastModified>='2022-01-05T08:05:37+00:00'].Key"

aws s3api list-buckets --output 'text' --query 'Buckets[].Name' | xargs -pn '1' aws s3api list-multipart-uploads --bucket
