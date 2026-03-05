# Manually add the AWS CLI MCP server.
jq --arg 'home' "$HOME" '.mcpServers."aws-api-ro" |= {
	"command": "docker",
	"args": [
		"run",
		"--rm",
		"--interactive",
		"--env", "AWS_REGION",
		"--env", "AWS_API_MCP_TELEMETRY",
		"--env", "READ_OPERATIONS_ONLY",
		"--volume", "$home/.aws:/app/.aws:ro",
		"public.ecr.aws/awslabs-mcp/awslabs/aws-api-mcp-server:latest"
	],
	"env": {
		"AWS_API_MCP_TELEMETRY": "false",
		"AWS_REGION": "eu-west-1",
		"READ_OPERATIONS_ONLY": "true"
	}
}' "$HOME/.claude.json" \
| sponge "$HOME/.claude.json"

# Add MCP servers.
# Scope defaults to 'local'.
claude mcp add 'aws-cli-ro' --scope 'user' \
	--env 'AWS_API_MCP_TELEMETRY=false' --env 'AWS_REGION=eu-west-1' --env 'READ_OPERATIONS_ONLY=true' \
	-- \
	docker run --rm --interactive --volume "$HOME/.aws:/app/.aws" \
		--env 'AWS_API_MCP_TELEMETRY' --env 'AWS_REGION' --env 'READ_OPERATIONS_ONLY' \
		'public.ecr.aws/awslabs-mcp/awslabs/aws-api-mcp-server:latest'
claude mcp add 'aws-cli-rw' --scope 'project' \
	--env 'AWS_API_MCP_TELEMETRY=false' --env 'AWS_API_MCP_PROFILE_NAME=operator' \
	--env 'AWS_REGION=eu-west-1' --env 'REQUIRE_MUTATION_CONSENT=true' \
	-- \
	docker run --rm --interactive --volume "$HOME/.aws:/app/.aws" \
		--env 'AWS_API_MCP_TELEMETRY' --env 'AWS_API_MCP_PROFILE_NAME' \
		--env 'AWS_REGION' --env 'REQUIRE_MUTATION_CONSENT' \
		'public.ecr.aws/awslabs-mcp/awslabs/aws-api-mcp-server:latest'
claude mcp add 'aws-cost-explorer' --scope 'user' \
	--env 'AWS_API_MCP_TELEMETRY=false' --env 'AWS_REGION=eu-west-1' \
	-- \
	docker run --rm --interactive --volume "$HOME/.aws:/app/.aws" \
		--env 'AWS_API_MCP_TELEMETRY' --env 'AWS_REGION' \
		'public.ecr.aws/awslabs-mcp/awslabs/cost-explorer-mcp-server:latest'
claude mcp add --transport 'http' 'gitlab' 'https://gitlab.example.org/api/v4/mcp'
claude mcp add 'grafana-aws' \
	--env 'GRAFANA_URL=https://g-abcdef0123.grafana-workspace.eu-west-1.amazonaws.com' \
	--env 'GRAFANA_SERVICE_ACCOUNT_TOKEN=glsa_abc…def' \
	-- \
	docker run --rm --interactive \
		--env 'GRAFANA_URL' --env 'GRAFANA_SERVICE_ACCOUNT_TOKEN' \
		'grafana/mcp-grafana:latest' -t 'stdio'
claude mcp add 'grafana-local' \
	--env 'GRAFANA_URL=http://localhost:3000' --env 'GRAFANA_USERNAME=kyle' --env 'GRAFANA_PASSWORD=somePassword' \
	--env 'GRAFANA_ORG_ID=1' \
	-- \
	docker run --rm --interactive \
		--env 'GRAFANA_URL' --env 'GRAFANA_USERNAME' --env 'GRAFANA_PASSWORD' --env 'GRAFANA_ORG_ID' \
		'grafana/mcp-grafana:latest' -t 'stdio'
claude mcp add --transport 'http' 'linear' 'https://mcp.linear.app/mcp' --scope 'user'
