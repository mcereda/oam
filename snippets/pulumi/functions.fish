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

function pulumi-ids
	pulumi stack export \
	| jq -r '.deployment.resources[].id' - \
	| sort
end

function pulumi-urn2id
	pulumi stack export \
	| jq -r --arg urn "$argv[1]" '.deployment.resources[]|select(.urn==$urn).id' -
end

# Examples:
# - $ pulumi-urnRegex2urn 'monitoring_instance$'
#   urn:pulumi:dev::start::aws:ec2/instance:Instance::monitoring-instance
function pulumi-urnRegex2urn
	pulumi stack export \
	| jq -r --arg regex "$argv[1]" '.deployment.resources[]|select(.urn|test($regex)).urn' -
end

function pulumi-urns
	pulumi stack export \
	| jq -r '.deployment.resources[].urn' - \
	| sort
end
