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

find '.' -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -print -exec yq '.backend.url' {} '+'

find '.' -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -exec dirname {} + | xargs -pn '1' pulumi install --cwd
find '.' -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -exec dirname {} + | xargs -pn '1' pulumi preview --parallel "$(nproc)" --cwd
find '.' -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -exec dirname {} + | xargs -pn '1' pulumi refresh --parallel "$(nproc)" -s 'dev' --non-interactive -v '3' --cwd

# Rename stacks
pulumi stack rename -s 'dev' 'staging'
# When the project name (and backend) changed
pulumi stack rename -s 'pulumicomuser/testproj/dev' 'organization/internal-services/dev'

# Get providers for resources
pulumi stack export | jq -r '.deployment.resources[]|{"urn":.urn,"provider":.provider}'

# Check providers are all of a specific version
pulumi stack export | jq -r '.deployment.resources[].provider' | grep -v 'aws::default_6_50_0'

# Avoid permission errors when deleting clusters with charts and stuff.
PULUMI_K8S_DELETE_UNREACHABLE='true' pulumi destroy

# Move rsources between stacks
pulumi state move --source 'organization/utils/dev' --dest 'organization/iam/dev' \
	'urn:pulumi:dev::utils::aws:iam/role:Role::rdsToS3Exporter' \
	'urn:pulumi:dev::utils::aws:iam/rolePolicy:RolePolicy::rdsToS3Exporter-allowExportingSnapshotsToS3'

# Upgrade providers' versions
jq '.dependencies."@pulumi/aws" |= "6.66.2"' 'package.json' | sponge 'package.json' \
&& pulumi install && pulumi update --suppress-outputs

# Import resources
pulumi import 'aws:ec2/instance:Instance' 'logstash' 'i-abcdef0123456789a'
pulumi import 'aws:ec2/securityGroup:SecurityGroup' 'internalOps' 'sg-0123456789abcdef0'
pulumi import 'aws:iam/user:User' 'jimmy' 'jimmy' --generate-code='false'
pulumi import 'aws:route53/record:Record' 'hoppscotch' 'ZGG4442BC3E8M_hoppscotch.example.org_A'
pulumi import 'aws:cloudwatch/metricAlarm:MetricAlarm' 'prometheus-ec2-CPUUtilization' 'prometheus-ec2-CPUUtilization-drc5644'
pulumi import 'aws:chatbot/slackChannelConfiguration:SlackChannelConfiguration' 'alarms' 'arn:aws:chatbot::012345678901:chat-configuration/slack-channel/alarms'
