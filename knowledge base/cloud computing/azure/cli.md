# Azure CLI

Queries (`az … --query …`) use the [JMESPath] query language for JSON.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Installation](#installation)
1. [Extensions](#extensions)
1. [Pipelines](#pipelines)
1. [AKS](#aks)
1. [APIs](#apis)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install the CLI.
asdf plugin add 'azure-cli' && asdf install 'azure-cli' '2.43.0'
brew install 'azure-cli'
docker run -v "${HOME}/.azure:/root/.azure" 'mcr.microsoft.com/azure-cli:2.40.0'
pip install 'azure-cli'
pipx install 'azure-cli'

# Disable certificates check upon connection.
# Use it for proxies with doubtful certificates.
export AZURE_CLI_DISABLE_CONNECTION_VERIFICATION=1

# Login to Azure.
az login
az login -u 'username' -p 'password'
az login --identity --username 'client_id__or__object_id__or__resource_id'
az login --service-principal \
  -u 'app_id' -p 'password_or_certificate' --tenant 'tenant_id'

# Check the CLI status.
az self-test

# Gather information on the current user.
az ad signed-in-user show
az ad signed-in-user list-owned-objects

# Gather information on another user.
az ad user show --id 'user@email.org'

# Check a User's permissions.
az ad user get-member-groups --id 'user@email.org'

# Get IDs of Service Principals from their Display Name.
# id => object ID, appId => client ID.
az ad sp list -o 'tsv' --display-name 'service_principal_name' --query '[].id'
az ad sp list … --query '[].appId'

# Get the Display Name of Service Principals from their object ID.
az ad sp show --query 'displayName' -o 'tsv' \
  --id '12345678-abcd-0987-fedc-567890abcdef'

# Show information about an Application.
# The ID must be an application id, object id or identifier uri.
az ad app show --id '12345678-abcd-0987-fedc-567890abcdef'

# Get the Display Name of an Application from its ID.
az ad app show --query 'displayName' -o 'tsv' \
  --id '12345678-abcd-0987-fedc-567890abcdef'

# Get the Principal (Object) ID of a Managed Identity from its Name.
az identity show --query 'principalId' -o 'tsv' \
  --resource-group 'resource_group_name' --name 'managed_identity_name'

# Get the name of a Managed Identity from its Principal (Object) ID.
az identity list -o 'tsv' \
  --query "[?(@.principalId=='managed_identity_principal_id')].name"

# Get a Resource Group's ID.
az group show 'resource_group_name'

# List Subscriptions available to the current User.
az account list --refresh --output 'table'

# Get the current User's default Subscription's ID.
az account show --query 'id' --output 'tsv'

# Get the ID of a Subscription from its Name.
az account show --query 'name' -o 'tsv' -s 'subscription_id'

# Get the Name of a Subscription from its ID.
az account show --query 'id' -o 'tsv' -n 'subscription_name'

# Get the current User's default Subscription.
az account set --subscription 'subscription_uuid__or__name'

# Set the current User's default Resource Group.
az configure --defaults 'group=resource_group_name'

# List available Locations.
az account list-locations -o 'table'

# Create an Access Token for the current User.
az account get-access-token
az account get-access-token --query 'accessToken' -o 'tsv'

# List and show role definitions.
az role definition list --name 'role_display_name'
az role definition list -g 'resource_group_name' --custom-role-only true

# Create role definitions.
az role definition create --role-definition 'full_json_definition'

# Update role definitions.
az role definition update --role-definition 'full_json_definition'
az role definition update --role-definition <( \
  az role definition list -g 'resource_group_name' --name 'role_display_name' \
  | jq -Mc '
    .[] | .assignableScopes += [
      "/subscription/subscription_id/resourceGroups/resource_group_name"
    ] ' - \
)

# Delete role definitions.
az role definition delete --name 'role_display_name'

# List role assignments.
az role assignment list
az role assignment list --all
az role assignment list --resource-group 'resource_group'
az role assignment list … --scope 'scope_id' --role 'role_id_or_name'

# List role assignments with scope for a User or Managed Identity.
# By default, it will only show role assignments for the current subscription.
az role assignment list --subscription 'subscription_id' \
  --all --include-inherited --assignee 'user_or_managed_identity_object_id' \
  --query '[].{role: roleDefinitionName, scope: scope}' -o 'tsv'

# Give Principals permissions on Key Vaults.
az keyvault set-policy -n 'key_vault_name' --object-id 'principal_object_id' \
  --secret-permissions 'get' 'list' 'set' --certificate-permissions 'all'
az keyvault set-policy -n 'key_vault_name' --spn 'service_principal_name' …
az keyvault set-policy -n 'key_vault_name' --upn 'user_principal_name' …

# List the names of all keys in Key Vaults.
az keyvault key list --query '[].name' -o 'tsv' --vault-name 'key_vault_name'

# Create or update passwords in Key Vaults.
az keyvault secret set \
  --vault-name 'key_vault_name' --name 'secret_name' --value 'plain_text'
az keyvault secret set … --expires '2024-04-10T12:19:54Z'

# Get passwords from Key Vaults.
az keyvault secret show --query 'value' \
  --name 'secret_name' --vault-name 'key_vault_name'

# Show details of Disk Encryption Sets.
az disk-encryption-set show -g 'resource_group_name' -n 'des_name'

# Get Key ID and Access Policy of Disk Encryption Sets.
az disk-encryption-set show --ids 'id' \
  --query "{
    \"keyId\": activeKey.keyUrl,
    \"accessPolicyId\": join('/', [activeKey.sourceVault.id, 'objectId', identity.principalId])
  }"

# List all the available SKUs for VMs.
az vm list-skus
az vm list-skus -l 'location'

# List all the SKUs supporting an ephemeral OS disk.
az vm list-skus -l 'location' -o tsv \
  --query "[?capabilities[?name=='EphemeralOSDiskSupported' && value=='True']]"

# List the Virtual Machine images available in Azure Marketplace.
# Or check https://az-vm-image.info .
# Suggested to use '--all' to avoid useless filtering at MSFT side.
az vm image list --all
az vm image list -l 'westus' --offer 'RHEL' -p 'RedHat' -s '8_5' --all

# Show a Virtual Machine's details.
az vm show -g 'resource_group_name' -n 'vm_name'

# Delete a Virtual Machine.
az vm delete -g 'resource_group_name' -n 'vm_name'

# Assess updates in a Linux Virtual Machine.
az vm assess-patches  -g 'resource_group_name'  -n 'vm_name'

# Install security updates in a Linux Virtual Machine.
# Do not reboot.
# Max 4h of operation.
az vm install-patches -g 'resource_group_name'  -n 'vm_name' \
  --maximum-duration 'PT4H' --reboot-settings 'Never' \
  --classifications-to-include-linux 'Security'

# Get the status of the Agent in a Virtual Machine.
az vm get-instance-view -g 'resource_group_name'  -n 'vm_name' \
  --query 'instanceView.vmAgent.statuses[]' -o 'table'

# Wait until a Virtual Machine satisfies a condition.
az vm wait -g 'resource_group_name'  -n 'vm_name' --created
az vm wait … --updated --interval '5' --timeout '300'
az vm wait … --custom "instanceView.statuses[?code=='PowerState/running']"
az vm wait … --custom "instanceView.vmAgent.statuses[?code!='ProvisioningState/Updating']"

# Wait for a Virtual Machine Agent to be Ready.
az vm wait -g 'resource_group_name'  -n 'vm_name' \
  --custom "instanceView.vmAgent.statuses[?code=='ProvisioningState/succeeded']"

# List all the available SKUs for PostgreSQL flexible DB servers.
az postgres flexible-server list-skus --location 'westeurope' -o 'table'

# List LogAnalytics' Workspaces.
az monitor log-analytics workspace list --query '[].name' \
  --resource-group 'resource_group_name'

# List available Resource Providers.
az provider list
az provider list --expand

# Enable a Resource Provider.
az provider register -n 'Microsoft.Confluent' --accept-terms
az provider register -n 'Microsoft.Automation' -m 'management_group_id'

# List the available properties of the 'ContainerService' Resource Provider.
az provider show -o 'tsv' --namespace 'Microsoft.ContainerService' \
  --expand 'resourceTypes/aliases' --query 'resourceTypes[].aliases[].name'

# Disable a Resource Provider.
az provider unregister -n 'Microsoft.Confluent'

# List available CLI extensions.
az extension list-available --output 'table'

# Add extensions to the CLI.
az extension add --name 'extension_name'
az extension add --source 'url__or__local_path'

# Update extensions.
az extension update --name 'extension_name'
az extension add --source 'updated__url__or__local_path'

# Remove installed extensions.
az extension remove --name 'extension_name'

# Validate a bicep template to create a Deployment Group.
# Leverages the `bicep` utility.
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

# Delete Log Analytics Workspaces.
az monitor log-analytics workspace delete -y -f 'y' \
  -g 'resource_group_name' -n 'law_name'

# Delete Disk Encryption Sets.
az disk-encryption-set delete -g 'resource_group_name' -n 'des_name'

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

# Show the servers in the default HTTP backend of an Application Gateway.
az network application-gateway show-backend-health -o 'table' \
  -g 'resource_group_name' -n 'agw_name' \
  --query 'backendAddressPools[].backendHttpSettingsCollection[].servers[]'

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

# List a User's PATs.
# 'displayFilterOptions' are 'active' (default), 'all', 'expired' or 'revoked'.
# 'displayFilterOptions' can be negated ('!revoked').
# If more then 20, or up to 100 using the '$top' url parameter, results are
# paged and a 'continuationToken' will be returned.
az rest -m 'get' \
  --headers Authorization='Bearer ey…pw' \
  -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats?api-version=7.1-preview.1'
az rest … -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats?api-version=7.1-preview.1&displayFilterOption=revoked&isSortAscending=false'
az rest … -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats' \
  --url-parameters 'api-version=7.1-preview.1' 'displayFilterOption=expired' continuationToken='Hr…in='

# Create PATs.
az rest -m 'post' \
  -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats' \
  --url-parameters 'api-version=7.1-preview.1' \
  --headers Authorization='Bearer ey…pw' Content-Type='application/json' \
  -b '{
    "displayName": "new-pat",
    "scope": "pat-scope",
    "validTo": "2021-12-31T23:46:23.319Z",
    "allOrgs": false
  }'

# Extend PATs.
# Works with expired PATs too, but not revoked ones.
az rest -m 'put' \
  -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats' \
  --url-parameters 'api-version=7.1-preview.1' \
  --headers Authorization='Bearer ey…pw' Content-Type='application/json' \
  -b '{
    "authorizationId": "01234567-abcd-0987-fedc-0123456789ab",
    "validTo": "2021-12-31T23:46:23.319Z"
  }'
az rest … -b @'file.json'

# Revoke PATs.
az rest -m 'delete' \
  -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats' \
  --url-parameters \
    'api-version=7.1-preview.1' \
    'authorizationId=01234567-abcd-0987-fedc-0123456789ab' \
  --headers Authorization='Bearer ey…pw'

# Automatically renew the first 100 non revoked Devops PATs.
# The others are in the next pages and not being able to deactivate pagination
# just su*ks bad.
# Assumes the command uses the GNU version of each tool (see `date`).
ORGANIZATION_NAME='organization_name' \
TOKEN="$(az account get-access-token --query 'accessToken' -o 'tsv')" \
VALID_TO="$(date -d '+13 days' '+%FT%T.00Z')" \
&& az rest -m 'get' \
     -u "https://vssps.dev.azure.com/${ORGANIZATION_NAME}/_apis/tokens/pats" \
     --url-parameters \
       'api-version=7.1-preview.1' \
       'displayFilterOption=!revoked' \
       '$top=100' \
     --headers "Authorization=Bearer ${TOKEN}" \
     --query 'patTokens[].authorizationId' \
     -o 'tsv' \
| parallel -qr -j '100%' \
    az rest -m 'put' \
      -u "https://vssps.dev.azure.com/${ORGANIZATION_NAME}/_apis/tokens/pats" \
      --url-parameters \
        'api-version=7.1-preview.1' \
      --headers \
        "Authorization=Bearer ${TOKEN}" \
        'Content-Type=application/json' \
      -b "{ \"authorizationId\": \"{}\", \"validTo\": \"${VALID_TO}\" }"
```

## Installation

```sh
pip install 'azure-cli'
brew install 'azure-cli'
asdf plugin add 'azure-cli' && asdf install 'azure-cli' '2.43.0'
docker run -it -v "${HOME}/.ssh:/root/.ssh" 'mcr.microsoft.com/azure-cli'
```

## Extensions

The Azure CLI can load _extensions_, practically Python wheels that aren't shipped as part of the CLI itself but run as CLI commands.<br/>
You could create your own CLI interface.

```sh
# List available CLI extensions.
az extension list-available --output 'table'

# Add extensions to the CLI.
az extension add --name 'extension_name'
az extension add --source 'url__or__local_path'

# Update extensions.
az extension update --name 'extension_name'
az extension add --source 'updated__url__or__local_path'

# Remove installed extensions.
az extension remove --name 'extension_name'
```

When you run a command for an extension which is not currently installed, CLI recognizes it and tries to automatically install the extension. This feature is called _dynamic install_, and is enabled by default since version 2.12.0.

```sh
# Configure if and how to use the 'dynamic install' feature.
az config set 'extension.use_dynamic_install=yes_prompt'
az config set 'extension.use_dynamic_install=yes_without_prompt'
az config set 'extension.use_dynamic_install=no'
az config set 'extension.run_after_dynamic_install=no'
```

## Pipelines

See [DevOps].

## AKS

See [AKS].

## APIs

One can directly call the APIs with the `rest` command:

```sh
az rest \
  -m 'post' \
  -u 'https://graph.microsoft.com/v1.0/me/checkMemberObjects' \
  --headers Authorization='Bearer ey…pw' \
  -b '{"ids": ["group_id"]}'

az rest \
  -m 'delete' \
  -u 'https://graph.microsoft.com/beta/groups/group_id/members/member_id/$ref'

az rest \
  -m 'put' \
  -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats?api-version=7.1-preview.1' \
  --headers \
    'Authorization=Bearer ey…pw' \
    'Content-Type=application/json' \
  -b '{
    "authorizationId": "01234567-abcd-0987-fedc-0123456789ab",
    "validTo": "2021-12-31T23:46:23.319Z"
  }'

az rest \
  -m 'get' \
  -u 'https://vssps.dev.azure.com/organization_name/_apis/tokens/pats' \
  --url-parameters \
    'api-version=7.1-preview.1' \
    'displayFilterOption=expired' \
    'continuationToken=Hr…in='
```

## Further readings

- [PAT APIs]
- The [`az` command reference][az reference]
- The [`az bicep` command group][az bicep]
- [Devops CLI extension]

## Sources

All the references in the [further readings] section, plus the following:

- [Install Azure CLI on macOS]
- [Get started with Azure CLI]
- [Sign in with Azure CLI]
- [How to manage Azure subscriptions with the Azure CLI]
- [Authenticate with an Azure container registry]
- [Remove a member]
- [Create and manage Azure Pipelines from the command line]

<!--
  References
  -->

<!-- Upstream -->
[authenticate with an azure container registry]: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-authentication?tabs=azure-cli
[az reference]: https://learn.microsoft.com/en-us/cli/azure/reference-index
[get started with azure cli]: https://learn.microsoft.com/en-us/cli/azure/get-started-with-azure-cli
[how to manage azure subscriptions with the azure cli]: https://learn.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli
[install azure cli on macos]: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-macos
[pat apis]: https://learn.microsoft.com/en-us/rest/api/azure/devops/tokens/pats
[remove a member]: https://learn.microsoft.com/en-us/graph/api/group-delete-members?view=graph-rest-1.0&tabs=http
[sign in with azure cli]: https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[aks]: aks.md
[az bicep]: bicep.md#tldr
[devops]: devops.md
[devops cli extension]: devops.md#tldr
[jmespath]: ../../jmespath.md

<!-- Others -->
[create and manage azure pipelines from the command line]: https://devblogs.microsoft.com/devops/create-and-manage-azure-pipelines-from-the-command-line/
