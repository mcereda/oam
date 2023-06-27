# Azure Devops

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Pipelines](#pipelines)
   1. [Predefined variables](#predefined-variables)
   1. [Loops](#loops)
1. [Azure CLI extension](#azure-cli-extension)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Login to Azure DevOps with a PAT.
az devops login --organization 'https://dev.azure.com/organization_name'

# Create new repositories.
az repos create --name 'repo_name' \
  --org 'https://dev.azure.com/organization_name' --project 'project_name'

# Delete repositories.
az repos delete --yes --id 'repo_id' \
  --org 'https://dev.azure.com/organization_name' --project 'project_name'

# Create pipelines from YAML definition files.
az pipelines create --name 'pipeline_name' \
  --org 'https://dev.azure.com/organization_name' --project 'project_name' \
  --repository 'repo_name' --repository-type 'tfsgit' \
  --folder-path '\\path\\to\\folder' --yaml-path '/path/in/repo.yaml' \
  --skip-first-run 'true'

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
az pipelines build show --detect 'true' -o 'tsv' \
  --project 'project_name' --id 'pipeline_id' --query 'result'

# Download an artifact uploaded during a Pipeline's run.
az pipelines runs artifact download --path 'local_path' \
  --organization 'organization_id_or_name' --project 'project_name' \
  --artifact-name 'artifact_name' --run-id 'run_id'

# Delete pipelines.
az pipelines delete --yes --id 'pipeline_id'

# List DevOps' Service Endpoints.
az devops service-endpoint list \
  --organization 'https://dev.azure.com/organization_name' --project 'project'
az rest -m 'get' \
  -u 'https://dev.azure.com/organization_name/project_name/_apis/serviceendpoint/endpoints' \
  --url-parameters 'api-version=7.1-preview.4' \
  --headers Authorization='Bearer ey…pw'

# Get the ID of a Service Endpoint from its name.
az devops service-endpoint list -o 'tsv' \
  --organization 'https://dev.azure.com/organization_name' --project 'project' \
  --query "[?name=='service_endpoint_name'].id"

# Get the name of a Service Endpoint from its id.
az devops service-endpoint list -o 'tsv' \
  --organization 'https://dev.azure.com/organization_name' --project 'project' \
  --query "[?id=='service_endpoint_id'].name"

# Filter out users whose Principal Name starts for X and access Y.
az devops user list --org 'https://dev.azure.com/organizationName' \
  --query "
    items[?
      startsWith(user.principalName, 'yourNameHere') &&
      \! contains(accessLevel.licenseDisplayName, 'Test plans')
    ].user.displayName"

# Get Teams' information.
az devops team show \
  --org 'https://dev.azure.com/organizationName' --project 'project' \
  --team 'display_name'
```

## Pipelines

Give the `--organization` parameter, or use `--detect true` if running the command from a git repository to have it guessed automatically.

`--detect` already defaults to `true`.

### Predefined variables

See [Use predefined variables] for more information.

### Loops

See [Expressions] for more information.

Use the `each` keyword to loop through **parameters of the object type**:

```yaml
parameters:
  - name: listOfFruits
    type: object
    default:
      - fruitName: 'apple'
        colors: ['red','green']
      - fruitName: 'lemon'
        colors: ['yellow']

steps:
  - ${{ each fruit in parameters.listOfFruits }} :
    - ${{ each fruitColor in fruit.colors}} :
      - script: echo ${{ fruit.fruitName}} ${{ fruitColor }}
```

## Azure CLI extension

Devops offers the [`az devops`][az devops] extension to the Azure CLI.<br/>
The extension will automatically install itself the first time you run an `az devops` command.

## Further readings

- [Expressions]
- [Use predefined variables]
- [Azure CLI]
- [`az devops`][az devops]

## Sources

All the references in the [further readings] section, plus the following:

- [Loops in Azure DevOps Pipelines]

<!-- project's references -->
[expressions]: https://learn.microsoft.com/en-us/azure/devops/pipelines/process/expressions
[use predefined variables]: https://learn.microsoft.com/en-us/azure/devops/pipelines/build/variables
[az devops]: https://learn.microsoft.com/en-us/cli/azure/devops?view=azure-cli-latest

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
[azure cli]: azure%20cli.md

<!-- external references -->
[loops in azure devops pipelines]: https://pakstech.com/blog/azure-devops-loops/
