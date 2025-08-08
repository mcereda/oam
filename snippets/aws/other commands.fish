#!/usr/bin/env fish

###
# Account
# ------------------
###

aws account enable-region --account-id '012345678901' --region-name 'af-south-1'
aws account get-region-opt-status --region-name 'af-south-1'
aws account disable-region --region-name 'af-south-1'


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
# Chatbot
# ------------------
###

# List Slack workspaces
aws chatbot describe-slack-workspaces
aws chatbot describe-slack-workspaces --query 'SlackWorkspaces'

# Show Slack channel configurations
aws chatbot describe-slack-channel-configurations
aws chatbot describe-slack-channel-configurations --query 'SlackChannelConfigurations'


###
# CloudFront
# ------------------
###

aws cloudfront get-distribution --id 'E123456ABCDEFG'
aws cloudfront get-cache-policy --id '01234567-89ab-cdef-0123-456789abcdef'


###
# CloudTrail
# ------------------
###

aws cloudtrail list-trails --query 'Trails[]'
aws cloudtrail describe-trails --trail-name-list 'ManagementEvents' --query 'trailList[0]'


###
# CloudWatch
# ------------------
###

# List available metrics
aws cloudwatch list-metrics --namespace 'AWS/EC2'
aws cloudwatch list-metrics --namespace 'AWS/EC2' --metric-name 'CPUUtilization'
aws cloudwatch list-metrics --namespace 'AWS/EC2' --dimensions 'Name=InstanceId,Value=i-1234567890abcdef0' \
	--query 'Metrics[].MetricName'

# Show alarms information
aws cloudwatch describe-alarms-for-metric --metric-name 'CPUUtilization' --namespace 'AWS/EC2' \
	--dimensions 'Name=InstanceId,Value=i-1234567890abcdef0'


###
# Cognito
# ------------------
###

# List user pools
# '--max-results' is required (ノಠ益ಠ)ノ彡┻━━┻
aws cognito-idp list-user-pools --max-results '10' --query 'UserPools'

# List users in pools
aws cognito-idp list-users --user-pool-id 'eu-west-1_lrDF9T78a' --query "Users[?Username=='john']"


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


###
# EFS
# ------------------
###

# Get filesystems' information.
aws efs describe-file-systems --query 'FileSystems' --creation-token 'fs-name'

# Get filesystems's ids.
aws efs describe-file-systems --query 'FileSystems[].FileSystemId' --output 'text' --creation-token 'fs-name'

# Print filesystems's DNS.
# No DNS nor region are returned from the get fs command, but ARN is and the DNS does follow a naming convention, so…
aws efs describe-file-systems --query 'FileSystems[].FileSystemArn' --output 'text' --creation-token 'fs-name' \
| sed -E 's|arn:[a-z-]+:elasticfilesystem:([a-z0-9-]+):[0-9]+:file-system/(fs-[a-f0-9]+)|\2.efs.\1.amazonaws.com|'

# Get mount targets' information.
aws efs describe-mount-targets --query 'MountTargets' --file-system-id 'fs-0123456789abcdef0'

# Get mount targets' IP address.
aws efs describe-mount-targets --query 'MountTargets[].IpAddress' --output 'text' --file-system-id 'fs-0123456789abcdef0'
aws efs describe-mount-targets --query 'MountTargets[].IpAddress' --output 'text' --mount-target-id 'fsmt-0123456789abcdef0'

# Get mount targets' IP address from the filesystem's name.
aws efs describe-mount-targets --query 'MountTargets[].IpAddress' --output 'json' \
	--file-system-id ( \
		aws efs describe-file-systems  --creation-token 'fs-name' --query 'FileSystems[].FileSystemId' --output 'text' \
	)

# Mount volumes.
mount -t 'nfs' -o 'nfsvers=4.0,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport' \
	'fs-0123456789abcdef0.efs.eu-west-1.amazonaws.com:/' "$HOME/efs"
mount -t 'nfs' -o 'nfsvers=4,tcp,rwsize=1048576,hard,timeo=600,retrans=2,noresvport' \
	'10.20.30.42:/export-name' "$HOME/efs/export"

# Update a file in an EFS volume, then stop the ECS tasks using it so new can start with the updated file.
mkdir -p "$HOME/tmp/efs" \
&&	aws efs describe-file-systems --query 'FileSystems[].FileSystemId' --output 'text' --creation-token 'mimir' \
	| xargs -I '%%' dig 'A' +short '@172.16.0.2' "%%.efs.eu-west-1.amazonaws.com" \
	| xargs -I '%%' mount -t 'nfs' -o 'nfsvers=4.0,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport' \
		"%%:/" "$HOME/tmp/efs" \
&&	sudo cp -iv 'config.yaml' "$HOME/tmp/efs/" \
&&	diff -q 'config.yaml' "$HOME/tmp/efs/config.yaml" \
&&	umount "$HOME/tmp/efs" \
&&	aws --profile 'ro' ecs list-tasks --cluster 'staging' --service-name 'mimir' --query 'taskArns' --output 'text' \
	| xargs -n '1' aws --profile 'rw' ecs stop-task --cluster 'staging' --output 'text' --query 'task.lastStatus' --task


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
# Grafana
# ------------------
###

aws grafana create-workspace-api-key --workspace-id 'g-abcdef0123' \
	--key-name 'test' --key-role 'VIEWER' --seconds-to-live '60'

aws grafana delete-workspace-api-key --workspace-id 'g-abcdef0123' --key-name 'test'



###
# IAM
# ------------------
###

# Create users
# Only 1 user can exist with a specific username, no matter its path
aws iam create-user --user-name 'quistis'
aws iam create-user --path '/alumni/' --user-name 'squall'

# Get users' information
aws iam get-user --user-name 'michele'

# Get information about user's console login capabilities
aws iam get-login-profile --user-name 'john' --query 'LoginProfile'

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

# Change users' console password
# FIXME: check
aws iam update-login-profile --user-name 'logan'
aws iam update-login-profile --user-name 'mike' --password 'newPassword' --password-reset-require

# Change one's own console password
# FIXME: check
basename (aws sts get-caller-identity --query 'Arn' --output 'text') \
| xargs aws iam update-login-profile --user-name

# Add users to user groups
aws iam add-user-to-group --group-name 'infra' --user-name 'matt'

# Delete users
aws iam delete-user --user-name 'sophie'


# Create roles
# Only 1 role can exist with a specific name, no matter its path
aws iam create-role --role-name 'captain' --assume-role-policy-document 'file://captain-trustPolicy.json'
aws iam create-role --role-name 'someService' --path '/services/' --assume-role-policy-document '{
	"Version": "2012-10-17",
	"Statement": [{
		"Sid": "AllowEc2ToAssumeThisVeryRole",
		"Effect": "Allow",
		"Principal": {
			"Service": "ec2.amazonaws.com"
		},
		"Action": "sts:AssumeRole"
	}]
}'

# Delete roles
aws iam delete-role --role-name 'someService'


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

aws kms decrypt --ciphertext-blob 'AQICA…0zzdXzQLAw='
aws kms decrypt --ciphertext-blob 'fileb://ciphertext.dat' --query 'Plaintext' --output 'text' \
| base64 --decode
aws kms decrypt --key-id 'arn:aws:kms:eu-west-1:123456789012:key/d74f5077-811b-4447-af65-71f5f64f37d3' \
	--ciphertext-blob 'fileb://enc.key.bin' --encryption-algorithm 'RSAES_OAEP_SHA_256' \
	--output 'text' --query 'Plaintext' \
| base64 --decode > 'decryptedKey.bin'

aws kms list-aliases --query 'Aliases[?AliasName.contains(@,`staging`)]'
aws kms list-aliases --query 'Aliases[?AliasName.contains(@,`prod`)]|[*].{"Alias":@.AliasName,"KeyId":@.TargetKeyId}'


###
# RDS
# ------------------
# Names are case-insensitive and will be shown as lowercase.
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
aws rds describe-db-parameters --db-parameter-group-name 'default.postgres15' \
	--output 'json' --query "Parameters[?ApplyType!='dynamic']"

aws rds create-db-snapshot --db-instance-identifier 'some-db-instance' --db-snapshot-identifier 'some-db-snapshot'


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

aws s3api list-buckets --output 'text' --query 'Buckets[].Name' | xargs -n '1' aws s3api list-multipart-uploads --bucket
aws --profile 'someProfile' s3api head-bucket --bucket 'someBucket'


###
# Secrets
# ------------------
###

aws secretsmanager create-secret --name 'TestSecretFromFile' --secret-string 'file://mycreds.json'
aws secretsmanager create-secret \
	--name 'MyTestSecret' --description 'A test secret created with the CLI.' \
	--secret-string '{"user":"diegor","password":"EXAMPLE-PASSWORD"}' \
	--tags '[{"Key": "FirstTag", "Value": "FirstValue"}, {"Key": "SecondTag", "Value": "SecondValue"}]'


###
# SNS
# ------------------
###

# List topics
aws sns list-topics

# Get information about topics
aws sns get-topic-attributes --topic-arn 'arn:aws:sns:eu-west-1:012345678901:aSucculentTopic'

# List subscriptions
aws sns list-subscriptions
aws sns list-subscriptions --query 'Subscriptions'
aws sns list-subscriptions-by-topic --topic-arn 'arn:aws:sns:eu-west-1:012345678901:aSucculentTopic'

# Get information about subscriptions
aws sns get-subscription-attributes \
	--subscription-arn 'arn:aws:sns:eu-west-1:012345678901:aSucculentTopic:abcdef01-2345-6789-abcd-ef0123456789'


###
# SSM
# ------------------
###

# Check SSM registered an EC2 instance
aws ssm get-connection-status --target 'i-0123456789abcdef0' --query 'Status' --output 'text'

# Start a shell
aws ssm start-session --target 'i-0123456789abcdef0'
