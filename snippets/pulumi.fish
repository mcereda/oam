#!/usr/bin/env fish

function pulumi-all-of-type
	pulumi stack export \
	| jq -r --arg type "$argv[1]" '.deployment.resources[]|select(.type==$type).urn' -
end

# Examples:
# - $ pulumi-all-of-typeRegex 'Endpoint$'
#   urn:pulumi:dev::ds::aws:sagemaker/endpoint:Endpoint::ml-endpoint
function pulumi-all-of-typeRegex
	pulumi stack export \
	| jq -r --arg regex "$argv[1]" '.deployment.resources[]|select(.type|test($regex)).urn' -
end

function pulumi-id2urn
	pulumi stack export \
	| jq -r --arg id "$argv[1]" '.deployment.resources[]|select(.id==$id).urn' -
end

function pulumi-urn2id
	pulumi stack export \
	| jq -r --arg urn "$argv[1]" '.deployment.resources[]|select(.urn==$urn).id' -
end

# Examples:
# - $ pulumi-urnRegex2urn 'gitlab_ee_main_instance$'
#   urn:pulumi:dev::start::aws:ec2/instance:Instance::monitoring-instance
function pulumi-urnRegex2urn
	pulumi stack export \
	| jq -r --arg regex "$argv[1]" '.deployment.resources[]|select(.urn|test($regex)).urn' -
end


pulumi pre
pulumi pre --cwd 'observability' --diff

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
pulumi plugin install


pulumi state unprotect 'urn:pulumi:dev::custom-images::aws:imagebuilder/infrastructureConfiguration:InfrastructureConfiguration::server-baseline'
pulumi state delete 'urn:pulumi:dev::custom-images::aws:imagebuilder/infrastructureConfiguration:InfrastructureConfiguration::server-baseline'
pulumi state rename -y 'urn:pulumi:dev::custom-images::aws:imagebuilder/imageRecipe:ImageRecipe::baselineServerImage-1.0.8' 'serverBaseline-1.0.8'


find . -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -exec dirname {} + | xargs -pn '1' pulumi preview --parallel "$(nproc)" --cwd
find . -type f -name 'Pulumi.yaml' -not -path "*/node_modules/*" -exec dirname {} + | xargs -pn '1' pulumi refresh --parallel "$(nproc)" -s 'dev' --non-interactive -v '3' --cwd
