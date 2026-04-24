#!/usr/bin/env fish

# Install Pulumi
brew install 'pulumi/tap/pulumi'

# Run in Docker.
docker run --rm --name 'pulumi-nodejs-3.127.0' -ti 'pulumi/pulumi-nodejs:3.127.0' --version
docker run --rm --name 'pulumi-nodejs-3.128.0' -ti --entrypoint 'bash' 'pulumi/pulumi-nodejs:3.128.0'
docker run --rm --name 'pulumi' \
	--env 'AWS_DEFAULT_REGION' --env 'AWS_ACCESS_KEY_ID' --env 'AWS_SECRET_ACCESS_KEY' --env 'AWS_PROFILE' \
	--env-file '.env' --env-file '.env.local' \
	-v '${PWD}:/pulumi/projects' -v '${HOME}/.aws:/root/.aws:ro' \
	'pulumi/pulumi-nodejs:3.148.0@sha256:2463ac69ec760635a9320b9aaca4e374a9c220f54a6c8badef35fd47c1da5976' \
	pulumi preview --suppress-outputs --stack 'dev'


# List available templates.
pulumi new -l
pulumi new --list-templates

# Create projects
pulumi new 'Python'
pulumi new 'TypeScript' … --name 'someTypescriptProject' --description 'Some TypeScript project'
pulumi new … --dir 'infrastructure' --stack 'production' --force
pulumi new … --secrets-provider 'awskms:///arn:aws:kms:eu-east-1:012345678901:key/0123abcd-4567-efab-8901-cdef01234567'


# Use Pulumi cloud to manage the state.
pulumi login
pulumi login --interactive 'https://api.pulumi.acmecorp.com'  # self-managed instance

# Manage the state locally.
pulumi login "file://~"
pulumi login --local                   # alias for `file://~`
pulumi login "file://."                # use the current directory
pulumi login "file://path/to/folder"   # use a specific directory

# Use cloud providers.
pulumi login 's3://some-bucket/with-prefix'   # aws
pulumi login 'azblob://state-bucket'          # azure
pulumi login 'gs://state-bucket'              # gpc

# Use other storage providers.
pulumi login 'postgres://username:password@host.fqdn:5432/database'   # postgresql

# Show information about the project's backend.
pulumi whoami -v
pulumi whoami --json
find '.' -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -print -exec yq '.backend.url' {} '+'

# Log out of backends.
# Deletes stored credentials on the local machine.
pulumi logout
pulumi logout --local
pulumi logout --all


# Show CLI debugging information.
pulumi about
pulumi about --stack 'dev'

# Reset the CLI configuration.
rm -r "$HOME/.pulumi"

# Configure autocompletion for the shell.
source <(pulumi gen-completion 'zsh')
pulumi gen-completion 'fish' > "$HOME/.config/fish/completions/pulumi.fish"


# Show the selected stack
pulumi stack --show-name

# View stacks' state.
pulumi stack
pulumi stack -ius 'stack-name'
pulumi stack --show-ids --show-urns --show-name --show-secrets

# List stacks.
pulumi stack ls
pulumi stack ls -o 'organization' -p 'project' -t 'tag'
pulumi stack ls -a

# Create stacks.
pulumi stack init 'prod'
pulumi stack init 'local' --copy-config-from 'dev' --no-select

# Select stacks.
pulumi select 'prod'

# Export stacks' state.
pulumi stack export
pulumi stack export -s 'dev' --show-secrets --file 'dev.stack.json'

# Import stacks' state.
pulumi stack import --file 'dev.stack.json'
pulumi stack import -s 'local' --file 'dev.stack.json'

# Delete stacks.
pulumi stack rm
pulumi stack rm -fy
pulumi stack rm --preserve-config --yes --stack 'stack'

# Create graphs of the dependency relations.
pulumi stack graph 'path/to/graph.dot'
pulumi stack graph -s 'dev' 'dev.dot' --short-node-name

# Rename stacks.
pulumi stack rename -s 'dev' 'staging'
# When the project name (and backend) changed
pulumi stack rename -s 'pulumicomuser/testproj/dev' 'organization/internal-services/dev'


# Configure the project.
pulumi config set 'boincAcctMgrUrl' 'https://bam.boincstats.com'
pulumi config set --secret 'boincGuiRpcPasswd' 'something-something-darkside'
pulumi config set --path 'outer.inner' 'value'
pulumi config set --path 'list[1]' 'value'
pulumi config set --secret someObject '{"someValue1": "someSecureValue", "someValue2": "someOtherSecureValue" }'
gpg --export 'smth@example.org' | pulumi config set 'smthTeam:pgpKey-public-raw' --type 'string'
cat "$HOME/.ssh/snowflake.key" | pulumi config set 'snowflake:privateKey' --secret

# Use terraform providers.
pulumi package add terraform-provider 'planetscale/planetscale'

# Configure providers.
pulumi config set 'gitlab:baseUrl' 'https://private.gitlab.server/api/v4/' # gitlab requires the ending slash
pulumi config set  --secret 'gitlab:token' 'glpat-m-Va…zy'

# Get the project's configuration.
pulumi config get 'boincAcctMgrUrl'
pulumi config get 'boincGuiRpcPasswd'
pulumi config get --path outer.inner
pulumi config get --path 'list[1]'

# Copy the project's configuration to stacks
pulumi config cp --dest 'local'
pulumi config cp --stack 'prod' --dest 'dev'


# Manage plugins.
pulumi plugin ls --project
pulumi plugin install --exact --reinstall
pulumi plugin rm --all --yes
pulumi plugin rm 'resource' 'aws' '6.20.1'


# Install projects' requirements.
pulumi install
pulumi install --reinstall
find '.' -type 'f' -name 'Pulumi.yaml' -not -path "*/node_modules/*" -print | tee \
| xargs -n1 dirname | tee | xargs -n1 -tI '%%' pulumi -C '%%' install
find '.' -type 'f' -name 'Pulumi.yaml' -not -path "*/node_modules/*" -exec dirname {} + \
| xargs -pn '1' pulumi install --cwd


# Preview changes.
pulumi pre
pulumi pre --cwd 'observability' --diff
pulumi pre --import-file 'resources.to.import.json'
pulumi pre --save-plan 'plan.json'
find '.' -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -exec dirname {} + \
| xargs -pn '1' pulumi preview --parallel "$(nproc)" --suppress-outputs --cwd
# With json summary (single JSON object, `| jq '.changeSummary' -`) for robotic usage
pulumi pre … --json --suppress-progress

# Show the URN (or other stuff) of resources that would be deleted
pulumi preview --json | jq -r '.steps[]|select(.op=="delete").urn' -
pulumi preview --json | jq -r '.steps[]|select(.op=="delete").oldState.id' -


# Import resources
# Could use `--suppress-outputs --generate-code='false' --protect=false` for some
pulumi import 'aws:alb/listener:Listener' 'pihole' 'arn:aws:elasticloadbalancing:us-west-2:012345678901:listener/app/pihole/0123456789abcdef/0123456789abcdef'
pulumi import 'aws:chatbot/slackChannelConfiguration:SlackChannelConfiguration' 'alarms' 'arn:aws:chatbot::012345678901:chat-configuration/slack-channel/alarms'
pulumi import 'aws:cloudfront/distribution:Distribution' 'someWebsite' 'E74FTE3EXAMPLE'
pulumi import 'aws:cloudwatch/logGroup:LogGroup' 'vulcan' 'vulcan'
pulumi import 'aws:cloudwatch/metricAlarm:MetricAlarm' 'prometheus-ec2-CPUUtilization' 'prometheus-ec2-CPUUtilization-drc5644'
pulumi import 'aws:codedeploy/application:Application' 'my-app-prod' 'my-application-production'
pulumi import 'aws:ec2/eipAssociation:EipAssociation' 'gitlab-server' 'eipassoc-abcd1234'
pulumi import 'aws:ec2/instance:Instance' 'logstash' 'i-abcdef0123456789a'
pulumi import 'aws:ec2/securityGroup:SecurityGroup' 'internalOps' 'sg-0123456789abcdef0'
pulumi import 'aws:ec2/subnet:Subnet' 'public_subnet' 'subnet-9d4a7b6c'
pulumi import 'aws:ecs/cluster:Cluster' 'experiments' 'experiments'
pulumi import 'aws:ecs/service:Service' 'pihole' 'experiments/pihole'
pulumi import 'aws:ecs/taskDefinition:TaskDefinition' 'pihole' 'arn:aws:ecs:eu-west-1:012345678901:task-definition/pihole:27'
pulumi import 'aws:iam/instanceProfile:InstanceProfile' 'prometheus-instance-profile' 'PrometheusRole'
pulumi import 'aws:iam/role:Role' 'developer' 'DeveloperRole'
pulumi import 'aws:iam/user:User' 'jimmy' 'jimmy'
pulumi import 'aws:imagebuilder/component:Component' 'requiredPackages' 'arn:aws:imagebuilder:us-east-1:123456789012:component/project-alpha-required-packages/1.0.0/1'
pulumi import 'aws:imagebuilder/imagePipeline:ImagePipeline' 'serverBase' 'arn:aws:imagebuilder:us-east-1:123456789012:image-pipeline/server-base'
pulumi import 'aws:rds/instance:Instance' 'staging' 'odoo-staging-replica'
pulumi import 'aws:route53/record:Record' 'hoppscotch' 'ZGG4442BC3E8M_hoppscotch.example.org_A'
pulumi import 'aws:secretsmanager/secret:Secret' 'example' 'arn:aws:secretsmanager:us-east-1:123456789012:secret:example-123456'
pulumi import 'aws:secretsmanager/secretVersion:SecretVersion' 'example' 'arn:aws:secretsmanager:us-east-1:123456789012:secret:example-123456|ABCDEF01-2345-6789-ABCD-EF0123456789'
pulumi import 'aws:vpc/securityGroupEgressRule:SecurityGroupEgressRule' 'allowAll' 'sgr-02108b27edd666983'
pulumi import 'aws:vpc/securityGroupIngressRule:SecurityGroupIngressRule' 'allowAll' 'sgr-02108b27edd666984'


# import children resources
# 1. get the parent's urn
pulumi stack --show-urns | grep "serviceUser.*someServiceUser"
# 2. import with `--parent`
pulumi import \
	'snowflake:index/userProgrammaticAccessToken:UserProgrammaticAccessToken' 'someServiceUser' 'SOME_SERVICE_PAT' \
	--parent 'urn:pulumi:dev::access::exampleOrg:StandardSnowflakeServiceAccount$snowflake:index/serviceUser:ServiceUser::someServiceUser'

# Import resources in block
#  1. pulumi preview --import-file 'import.json'
#  2. change <PLACEHOLDER> with the ids
#  3. pulumi import --file 'import.json'


# List outputs.
pulumi stack output --json | jq '.|keys'

# Access outputs.
pulumi stack output 'vpcId'
pulumi stack output 'subnetName' --show-secrets -s 'stack'
pulumi stack output --json 'redis' | jq -r '.replicationGroup | "redis://\(.primaryEndpointAddress):\(.port)"'

# Apply changes.
pulumi up --suppress-outputs --show-secrets
pulumi up --exclude 'urn:pulumi:…'
pulumi up --plan 'plan.json'
# With json summary (NDJSON stream, `| jq -s '[.[] | select(.type == "summary") -`) for robotic usage
pulumi up … --json --suppress-progress

# Limit the application run to only execute the 'delete' operations.
pulumi pre --suppress-outputs --json \
| jq -r '.steps[]|select(.op=="delete").urn' - \
| sed 's/^/-t /g' \
| xargs -o pulumi up --suppress-outputs


# Refresh the project's state.
pulumi refresh
pulumi refresh --suppress-outputs --diff
find '.' -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -exec dirname {} + \
| xargs -pn '1' pulumi refresh --parallel "$(nproc)" -s 'dev' --non-interactive -v '3' --cwd


# Manually change the project's state.
pulumi state unprotect 'urn:pulumi:dev::custom-images::aws:imagebuilder/infrastructureConfiguration:InfrastructureConfiguration::server-baseline'
pulumi state delete 'urn:pulumi:dev::custom-images::aws:imagebuilder/infrastructureConfiguration:InfrastructureConfiguration::server-baseline'
pulumi state rename -y 'urn:pulumi:dev::custom-images::aws:imagebuilder/imageRecipe:ImageRecipe::baselineServerImage-1.0.8' 'serverBaseline-1.0.8'
EDITOR='vim' pulumi state edit

# Remove all resources that *would* be deleted from the current state
pulumi preview --json | jq -r '.steps[]|select(.op=="delete").urn' - | xargs -n1 pulumi state delete --force

# Move resources between stacks
pulumi state move --source 'organization/utils/dev' --dest 'organization/iam/dev' \
	'urn:pulumi:dev::utils::aws:iam/role:Role::rdsToS3Exporter' \
	'urn:pulumi:dev::utils::aws:iam/rolePolicy:RolePolicy::rdsToS3Exporter-allowExportingSnapshotsToS3'


# Change secrets providers.
pulumi stack change-secrets-provider 'awskms://1234abcd-12ab-34cd-56ef-1234567890ab?region=us-east-1'
pulumi stack change-secrets-provider 'hashivault://deezKeyz'


# Take down the whole stack.
pulumi destroy
pulumi down --target 'urn:pulumi:…'
pulumi dn --stack 'dev' --exclude-protected


# Get the AWS secret access key of an aws.iam.AccessKey resource
pulumi stack output 'someAccessKey' | jq -r '.encryptedSecret' - | base64 -d | gpg --decrypt
pulumi stack export \
| jq -r '
	.deployment.resources[]
	| select(.type=="aws:iam/accessKey:AccessKey" and .outputs.user=="someUserId")
	| .outputs.encryptedSecret' \
| base64 -d | gpg -d


# Get the initial password created by an aws.iam.UserLoginProfile resource.
# If no encryption is set in the resource, it will be available in plaintext at runtime as the resource's
#   'encryptedPassword' attribute - just log it out.
# If a PGP key is set in the resource, it will be available as base64 cyphertext at runtime as the resource's
#   'encryptedPassword' attribute *and* it will also be available in the state for later reference.
pulumi stack output 'someUserLoginProfile' | jq -r '.encryptedPassword' - | base64 -d | gpg --decrypt
pulumi stack export \
| jq -r '
	.deployment.resources[]
	| select(.type=="aws:iam/userLoginProfile:UserLoginProfile" and .id=="someUserId")
	| .outputs.encryptedPassword' \
| base64 -d | gpg -d


# Avoid permission errors when deleting clusters with charts and stuff.
PULUMI_K8S_DELETE_UNREACHABLE='true' pulumi destroy


# Show providers used by the project's resources
pulumi stack export | jq -r '.deployment.resources[]|{"urn":.urn,"provider":.provider}'

# Upgrade providers' versions in projects' definition files.
jq '.dependencies."@pulumi/aws" |= "6.66.2"' 'package.json' | sponge 'package.json' \
&& pulumi install && pulumi update --suppress-outputs

# Update only resources with a specific provider version.
pulumi update --suppress-output ( \
	pulumi stack export \
	| jq -r '.deployment.resources[]|select(.provider)|select(.provider|test("6.80.0")).urn' \
	| sed 's/^/-t /g' \
	| xargs \
)

# Check all resource providers are using a specific version
pulumi stack export | jq -r '.deployment.resources[].provider' | grep -v 'aws::default_6_50_0'


# Enable patch force for target resources (k8s-helm only)
PULUMI_K8S_ENABLE_PATCH_FORCE='true' \
pulumi up --target 'urn:pulumi:someStack::someProj::kubernetes:helm.sh/v4:Chart$kubernetes:apiextensions.k8s.io/v1:CustomResourceDefinition::awsLoadBalancerController:targetgroupbindings.elbv2.k8s.aws'
