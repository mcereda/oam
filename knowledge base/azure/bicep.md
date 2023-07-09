# Bicep

Domain-specific language (DSL) for Infrastructure as Code, using declarative syntax to deploy Azure resources in a consistent manner.

See the [What is Bicep?] page for more information.

The Azure CLI can use a command group (`az bicep …`) to integrate with the `bicep` utility.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Utility management](#utility-management)
   1. [Installation](#installation)
   1. [Upgrade](#upgrade)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Install the `bicep` utility.
# Includes the utility inside the local Azure CLI installation's path.
az bicep install
az bicep install -v 'v0.2.212' -t 'linux-arm64'

# The CLI defaults to the included installation.
# External instances of the `bicep` utility *can* be used *if* the CLI is
# configured to do so.
brew install azure/bicep/bicep && \
az config set bicep.use_binary_from_path=True

# Upgrade `bicep` from the CLI.
az bicep upgrade
az bicep upgrade -t 'linux-x64'

# Validate a bicep template to create a Deployment Group.
# Leverages the `bicep` utility.
az deployment group validate \
  -n 'deployment_group_name' -g 'resource_group_name' \
  -f 'template.bicep' -p 'parameter1=value' parameter2="value"
```

## Utility management

### Installation

The simplest way to install the `bicep` utility is to use the CLI:

```sh
az bicep install
az bicep install -v 'v0.2.212' -t 'linux-arm64'
```

When doing so, the CLI downloads the utility inside its path.

When using a proxy (like in companies forcing connections through it), the certificate check might fail.<br/>
If this is the case, or when needed, `bicep` **can** be installed externally and used by the CLI, **if** the CLI is configured to use it with the following setting:

```sh
az config set bicep.use_binary_from_path=True
```

### Upgrade

Bicep will by default check for upgrades when run.<br/>
To avoid this, the CLI needs to be configured to as follows:

```sh
az config set bicep.version_check=False
```

When `bicep` is installed through the CLI, it can be updated from it too:

```sh
az bicep upgrade
az bicep upgrade -t 'linux-x64'
```

## Further readings

- [What is Bicep?]
- The [`az bicep` command reference][az bicep]
- The [Azure CLI]

<!--
  References
  -->

<!-- Upstream -->
[az bicep]: https://learn.microsoft.com/en-us/cli/azure/bicep
[what is bicep?]: https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview

<!-- Knowledge base -->
[azure cli]: cli.md
