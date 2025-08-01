#!/usr/bin/env fish

brew install 'pulumi/tap/pulumi'

pulumi login
pulumi login 's3://some-bucket/with-prefix'
pulumi whoami -v

rm -r "$HOME/.pulumi"

source <(pulumi gen-completion 'zsh')
pulumi gen-completion 'fish' > "$HOME/.config/fish/completions/pulumi.fish"

docker run --rm --name 'pulumi-nodejs-3.127.0' -ti 'pulumi/pulumi-nodejs:3.127.0' --version
docker run --rm --name 'pulumi-nodejs-3.128.0' -ti --entrypoint 'bash' 'pulumi/pulumi-nodejs:3.128.0'
docker run --rm --name 'pulumi' \
	--env 'AWS_DEFAULT_REGION' --env 'AWS_ACCESS_KEY_ID' --env 'AWS_SECRET_ACCESS_KEY' --env 'AWS_PROFILE' \
	--env-file '.env' --env-file '.env.local' \
	-v '${PWD}:/pulumi/projects' -v '${HOME}/.aws:/root/.aws:ro' \
	'pulumi/pulumi-nodejs:3.148.0@sha256:2463ac69ec760635a9320b9aaca4e374a9c220f54a6c8badef35fd47c1da5976' \
	pulumi preview --suppress-outputs --stack 'dev'

pulumi install
pulumi install --reinstall

pulumi pre
pulumi pre --cwd 'observability' --diff
pulumi up --suppress-outputs

# Get the URN (or other stuff) of resources that would be deleted
pulumi preview --json | jq -r '.steps[]|select(.op=="delete").urn' -
pulumi preview --json | jq -r '.steps[]|select(.op=="delete").oldState.id' -

# Remove from the state all resources that would be deleted
pulumi preview --json | jq -r '.steps[]|select(.op=="delete").urn' - | xargs -n1 pulumi state delete --force

pulumi config set 'boincAcctMgrUrl' 'https://bam.boincstats.com'
pulumi config set --secret 'boincGuiRpcPasswd' 'something-something-darkside'
pulumi config set --path 'outer.inner' 'value'
pulumi config set --path 'list[1]' 'value'
gpg --export 'smth@example.org' | pulumi config set 'smthTeam:pgpKey-public-raw' --type 'string'
cat "$HOME/.ssh/snowflake.key" | pulumi config set 'snowflake:privateKey' --secret

# Gitlab provider
# 'baseUrl' requires the ending slash
pulumi config set 'gitlab:baseUrl' 'https://private.gitlab.server/api/v4/'
pulumi config set 'gitlab:token' 'glpat-m-Va…zy' --secret

pulumi config get 'boincAcctMgrUrl'
pulumi config get 'boincGuiRpcPasswd'
pulumi config get --path outer.inner
pulumi config get --path 'list[1]'

pulumi plugin ls --project
pulumi plugin install --exact --reinstall
pulumi plugin rm --all --yes
pulumi plugin rm 'resource' 'aws' '6.20.1'

pulumi state unprotect 'urn:pulumi:dev::custom-images::aws:imagebuilder/infrastructureConfiguration:InfrastructureConfiguration::server-baseline'
pulumi state delete 'urn:pulumi:dev::custom-images::aws:imagebuilder/infrastructureConfiguration:InfrastructureConfiguration::server-baseline'
pulumi state rename -y 'urn:pulumi:dev::custom-images::aws:imagebuilder/imageRecipe:ImageRecipe::baselineServerImage-1.0.8' 'serverBaseline-1.0.8'

pulumi state edit
EDITOR='vim' pulumi state edit

find '.' -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -print -exec yq '.backend.url' {} '+'

find '.' -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -exec dirname {} + | xargs -pn '1' pulumi install --cwd
find '.' -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -exec dirname {} + | xargs -pn '1' pulumi preview --parallel "$(nproc)" --cwd
find '.' -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -exec dirname {} + | xargs -pn '1' pulumi refresh --parallel "$(nproc)" -s 'dev' --non-interactive -v '3' --cwd

# View the selected stack
pulumi stack --show-name

# Rename stacks
pulumi stack rename -s 'dev' 'staging'
# When the project name (and backend) changed
pulumi stack rename -s 'pulumicomuser/testproj/dev' 'organization/internal-services/dev'

# Get providers for resources
pulumi stack export | jq -r '.deployment.resources[]|{"urn":.urn,"provider":.provider}'

# Check providers are all of a specific version
pulumi stack export | jq -r '.deployment.resources[].provider' | grep -v 'aws::default_6_50_0'

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

# Move resources between stacks
pulumi state move --source 'organization/utils/dev' --dest 'organization/iam/dev' \
	'urn:pulumi:dev::utils::aws:iam/role:Role::rdsToS3Exporter' \
	'urn:pulumi:dev::utils::aws:iam/rolePolicy:RolePolicy::rdsToS3Exporter-allowExportingSnapshotsToS3'

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

# Limit the update run to only execute the 'delete' operations.
pulumi pre --suppress-outputs --json \
| jq -r '.steps[]|select(.op=="delete").urn' - \
| sed 's/^/-t /g' \
| xargs -o pulumi update --suppress-outputs

# Enable patch force for target resources (k8s-helm only)
PULUMI_K8S_ENABLE_PATCH_FORCE='true' \
pulumi up --target 'urn:pulumi:someStack::someProj::kubernetes:helm.sh/v4:Chart$kubernetes:apiextensions.k8s.io/v1:CustomResourceDefinition::awsLoadBalancerController:targetgroupbindings.elbv2.k8s.aws'

# Import resources
# Could use `--suppress-outputs --generate-code='false' --protect=false` for some
pulumi import --file 'import.json'
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
pulumi import 'aws:iam/user:User' 'jimmy' 'jimmy'
pulumi import 'aws:imagebuilder/component:Component' 'requiredPackages' 'arn:aws:imagebuilder:us-east-1:123456789012:component/project-alpha-required-packages/1.0.0/1'
pulumi import 'aws:imagebuilder/imagePipeline:ImagePipeline' 'serverBase' 'arn:aws:imagebuilder:us-east-1:123456789012:image-pipeline/server-base'
pulumi import 'aws:rds/instance:Instance' 'staging' 'odoo-staging-replica'
pulumi import 'aws:route53/record:Record' 'hoppscotch' 'ZGG4442BC3E8M_hoppscotch.example.org_A'
pulumi import 'aws:secretsmanager/secret:Secret' 'example' 'arn:aws:secretsmanager:us-east-1:123456789012:secret:example-123456'
pulumi import 'aws:secretsmanager/secretVersion:SecretVersion' 'example' 'arn:aws:secretsmanager:us-east-1:123456789012:secret:example-123456|ABCDEF01-2345-6789-ABCD-EF0123456789'
pulumi import 'aws:vpc/securityGroupEgressRule:SecurityGroupEgressRule' 'allowAll' 'sgr-02108b27edd666983'
pulumi import 'aws:vpc/securityGroupIngressRule:SecurityGroupIngressRule' 'allowAll' 'sgr-02108b27edd666984'
