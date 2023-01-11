# Azure CLI

1. [TL;DR](#tldr)
2. [Pipelines](#pipelines)
3. [APIs](#apis)
4. [Further readings](#further-readings)
5. [Sources](#sources)

## TL;DR

```sh
# Install the CLI.
brew install 'azure-cli'
asdf plugin add 'azure-cli' && asdf install 'azure-cli' '2.43.0'

# Disable certificates check upon connection.
# Use it for proxies with doubtful certificates.
export AZURE_CLI_DISABLE_CONNECTION_VERIFICATION=1

# Login to Azure.
az login
az login -u 'username' -p 'password'
az login --identity --username 'client_id__or__object_id__or__resource_id'
az login --service-principal \
  -u 'app_id' -p 'password_or_certificate' --tenant 'tenant_id'

# Gather information on the current user.
az ad signed-in-user show
az ad signed-in-user list-owned-objects

# Gather information on another user.
az ad user show --id 'user@email.org'

# Check a User's permissions.
az ad user get-member-groups --id 'user@email.org'

# Get the ID of a Service Principal from its Display Name.
az ad sp list --query 'id' -o 'tsv' --display-name 'service_principal_name'

# Get the Display Name of a Service Principal from its ID.
az ad sp show --query 'displayName' -o 'tsv' \
  --id '12345678-abcd-0987-fedc-567890abcdef'

# Get a Resource Group's ID.
az group show 'resource_group_name'

# List Subscriptions available to the current User.
az account list --refresh --output 'table'

# Get the current User's default Subscription's ID.
az account show --query 'id' --output 'tsv'

# Get the current User's default Subscription.
az account set --subscription 'subscription_uuid_or_name'

# Set the current User's default Resource Group.
az configure --defaults 'group=resource_group_name'

# List available Locations.
az account list-locations -o 'table'

# Create an Access Token for the current User.
az account get-access-token

# List role assignments.
az role assignment list
az role assignment list --all
az role assignment list --resource-group 'resource_group'
az role assignment list … --scope 'scope_id' --role 'role_id_or_name'

# List role assignments with scope for a User or Managed Identity.
# By default, it will only show role assignments for the current subscription.
az role assignment list --subscription 'subscription_id' \
  --all --include-inherited --assignee 'user_or_managed_identity_object_id' \
  --query '[].{role: roleDefinitionName, scope: scope}' -o tsv

# List the names of all keys in a KeyVault.
az keyvault key list --query '[].name' -o tsv --vault-name 'key_vault_name'

# Get a password from a KeyVault.
az keyvault secret show --query 'value' \
  --name 'secret_name' --vault-name 'key_vault_name'

# List LogAnalytics' Workspaces.
az monitor log-analytics workspace list \
  --resource-group 'resource_group_name' \
| jq -r '.[].name' -

# Login to Azure DevOps with a PAT.
az devops login --organization 'https://dev.azure.com/organization_name'

# Get the names of all the Pipelines the current user has access to.
az pipelines list --organization 'organization_id_or_name'
az pipelines list --detect 'true' --query '[].name' -o 'tsv'

# Show a specific Pipeline information.
az pipelines show --id 'pipeline_id'
az pipelines show --name 'pipeline_name'

# Start a Pipeline run.
az pipelines run --name 'pipeline_name' \
  --parameters 'system.debug=True' agent.diagnostic="True"

# Get the status of a Pipeline's build run.
az pipelines build show --id 'pipeline_id'
az pipelines build show --detect true -o 'tsv' \
  --project 'project_name' --id 'pipeline_id' --query 'result'

# Download an artifact uploaded during a Pipeline's run.
az pipelines runs artifact download --path 'local_path' \
  --organization 'organization_id_or_name' --project 'project_name' \
  --artifact-name 'artifact_name' --run-id 'run_id'

# Validate a bicep template to create a Deployment Group.
az deployment group validate \
  -n 'deployment_group_name' -g 'resource_group_name' \
  -f 'template.bicep' -p 'parameter1=value' parameter2="value"

# Check what a bicep template would do.
az deployment group what-if …

# Create a Deployment Group from a template.
az deployment group create …

# Cancel the current operation on a Deployment Group.
az deployment group cancel \
  -n 'deployment_group_name' -g 'resource_group_name'

# Delete a Deployment Group.
az deployment group delete \
  -n 'deployment_group_name' -g 'resource_group_name'

# Login to an ACR.
az acr login --name 'acr_name'

# Diagnose container registry connectivity issues.
# Requires Docker being running.
# Will run a hello-world image locally.
az acr check-health -n 'acr_name' -s 'subscription_uuid_or_name'

# List helm charts in an ACR.
az acr helm list -n 'acr_name' -s 'subscription_uuid_or_name'

# Get the 5 latest versions of a helm chart in an ACR.
az acr helm list -n 'acr_name' -s 'subscription_uuid_or_name' -o 'json' \
| jq \
  --arg CHART_REGEXP 'chart_name_or_regex' \
  'to_entries
    | map(select(.key|test($CHART_REGEXP)))[].value[]
    | { version: .version, created: .created }' - \
| yq -sy 'sort_by(.created) | reverse | .[0:5]' -

# Push a helm chart to an ACR.
az acr helm push -n 'acr_name' 'chart.tgz' --force

# List the available AKS versions.
az aks get-versions --location 'location' -o table

# Show the details of an AKS cluster.
az aks show -g 'resource_group_name' -n 'cluster_name'

# Get credentials for an AKS cluster.
az aks get-credentials \
  --resource-group 'resource_group_name' --name 'cluster_name'
az aks get-credentials … --overwrite-existing --admin

# Move the cluster to its goal state *without* changing its configuration.
# Can be used to move out of a non succeeded state.
az aks update --resource-group 'resource_group_name' --name 'cluster_name' --yes

# Validate an ACR is accessible from an AKS cluster.
az aks check-acr --acr 'acr_name' \
  --resource-group 'resource_group_name' --name 'cluster_name'
az aks check-acr … --node-name 'node_name'

# Add a new AKS extensions.
az aks extension add --name 'k8s-extension'

# Show the details of an installed AKS extensions.
az aks extension show --name 'k8s-extension'

# List Kubernetes extensions of an AKS cluster.
az k8s-extension list --cluster-type 'managedClusters' \
  --resource-group 'resource_group_name' --name 'cluster_name'

# List Flux configurations in an AKS cluster.
az k8s-configuration flux list --cluster-type 'managedClusters' \
  --resource-group 'resource_group_name' --name 'cluster_name'

# List the available Features in a Subscription.
az feature list

# Show the details of a Feature.
az feature show -n 'AKS-ExtensionManager' --namespace 'Microsoft.ContainerService'

# List Policies.
az policy definition list
az policy definition list -o 'tsv' --query "[?(@.name=='policy_name')]"
az policy definition list -o 'tsv' --query "[?(@.displayName=='policy_display_name')].name"

# Show a Policy's definition.
az policy definition show -n 'policy_name'

# List Policies metadata.
az policy metadata list

# List Policy Initiatives.
az policy set-definition list
az policy set-definition list -o 'tsv' --query "[?(@.name=='initiative_name')]"
az policy set-definition list --management-group 'management_group_id' \
  -o 'tsv' --query "[?(@.displayName=='initiative_display_name')].name"

# Show an Initiative's definition.
az policy set-definition show -n 'initiative_name'

# Check if the current User is member of a given Group.
az rest -u 'https://graph.microsoft.com/v1.0/me/checkMemberObjects' \
  -m post -b '{"ids":["group_id"]}'

# Check if a Service Principal is member of a given Group.
az rest -u 'https://graph.microsoft.com/v1.0/servicePrincipals/service_principal_id/checkMemberObjects' \
  -m post -b '{"ids":["group_id"]}'

# Query the Graph APIs for a specific Member in a Group.
az rest -m 'get' \
  -u 'https://graph.microsoft.com/beta/groups/group_id/members?$search="displayName:group_display_name"&$select=displayName' \
  --headers 'consistencylevel=eventual'

# Remove a Member from an AAD Group.
# If '/$ref' is missing from the request, the user will be **deleted from AAD**
# if the appropriate permissions are used, otherwise a '403 Forbidden' error is
# returned.
az rest -m 'delete' \
  -u 'https://graph.microsoft.com/beta/groups/group_id/members/member_id/$ref'

# List the PATs of a User.
# 'displayFilterOptions' are 'active' (default), 'all', 'expired' or 'revoked'.
# If more then 20, results are paged and a 'continuationToken' will be returned.
az rest -m 'get' \
  --headers Authorization='Bearer ey…pw' \
  -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats?api-version=7.1-preview.1'
az rest … -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats?api-version=7.1-preview.1&displayFilterOption=revoked&isSortAscending=false'
az rest … -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats' \
  --url-parameters 'api-version=7.1-preview.1' 'displayFilterOption=expired' continuationToken='Hr…in='

# Extend a PAT.
# Works with expired PATs too.
az rest \
  -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats?api-version=7.1-preview.1' \
  -m 'put' \
  --headers Authorization='Bearer ey…pw' Content-Type='application/json' \
  -b '{
	  "authorizationId": "01234567-abcd-0987-fedc-0123456789ab",
	  "validTo": "2021-12-31T23:46:23.319Z"
  }'
az rest … -b @'file.json'
```

## Pipelines

Give the `--organization` parameter, or use `--detect true` if running the command from a git repository to have it guessed automatically.

`--detect` already defaults to `true`.

## APIs

One can directly call the APIs with the `rest` command:

```sh
az rest \
  -u 'https://graph.microsoft.com/v1.0/me/checkMemberObjects' \
  --headers Authorization='Bearer ey…pw' \
  -m 'post' \
  -b '{"ids": ["group_id"]}'

az rest \
  -u 'https://graph.microsoft.com/beta/groups/group_id/members/member_id/$ref' \
  -m 'delete'

az rest \
  -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats?api-version=7.1-preview.1' \
  -m 'put' \
  --headers \
    'Authorization=Bearer ey…pw' \
    'Content-Type=application/json' \
  -b '{
	  "authorizationId": "01234567-abcd-0987-fedc-0123456789ab",
	  "validTo": "2021-12-31T23:46:23.319Z"
  }'

az rest \
  -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats' \
  -m 'get'
  --url-parameters \
    'api-version=7.1-preview.1' \
    'displayFilterOption=expired' \
    'continuationToken=Hr…in='
```

## Further readings

- [Pat token APIs]

## Sources

- [Install Azure CLI on macOS]
- [Get started with Azure CLI]
- [Sign in with Azure CLI]
- [How to manage Azure subscriptions with the Azure CLI]
- [Authenticate with an Azure container registry]
- [Remove a member]
- [az aks reference]
- [Create and manage Azure Pipelines from the command line]

<!-- external references -->
[authenticate with an azure container registry]: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication?tabs=azure-cli
[az aks reference]: https://learn.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest
[create and manage azure pipelines from the command line]: https://devblogs.microsoft.com/devops/create-and-manage-azure-pipelines-from-the-command-line/
[get started with azure cli]: https://docs.microsoft.com/en-us/cli/azure/get-started-with-azure-cli
[how to manage azure subscriptions with the azure cli]: https://docs.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli
[install azure cli on macos]: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos
[pat token apis]: https://docs.microsoft.com/en-us/rest/api/azure/devops/tokens/pats/list?view=azure-devops-rest-7.1
[remove a member]: https://docs.microsoft.com/en-us/graph/api/group-delete-members?view=graph-rest-1.0&tabs=http
[sign in with azure cli]: https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli
