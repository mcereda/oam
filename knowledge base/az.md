# Azure CLI

## TL;DR

```sh
# login
az login

# check a user's permissions
az ad user get-member-groups --id user@email.org

# list available subscriptions
az account list --refresh --output table

# set a default subscription
az account set --subscription subscription-uuid

# set a default resource group
az configure --defaults group=resource-group

# get credentials for an aks cluster
az aks get-credentials --resource-group resource-group --name cluster-name --overwrite-existing

# diagnose container registry connectivity issues
# will run a hello-world image locally
az acr check-health --name acr-name

# list helm charts in an acr
az acr helm list -n acr-name -s acr-subscription

# push a helm chart to an acr
az acr helm push -n acr-name chart.tgz --force

# disable connection verification
# for proxies with doubtful certificates
export AZURE_CLI_DISABLE_CONNECTION_VERIFICATION=1
```

## Sources

- [Install Azure CLI on macOS]
- [Get started with Azure CLI]
- [Sign in with Azure CLI]
- [How to manage Azure subscriptions with the Azure CLI]


[Get started with Azure CLI]: https://docs.microsoft.com/en-us/cli/azure/get-started-with-azure-cli
[How to manage Azure subscriptions with the Azure CLI]: https://docs.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli
[Install Azure CLI on macOS]: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-macos
[Sign in with Azure CLI]: https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli
