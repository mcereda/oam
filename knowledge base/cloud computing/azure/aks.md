# Azure Kubernetes Service

Managed Kubernetes solution offered by Azure.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Troubleshooting](#troubleshooting)
   1. [_Subnet XXX does not have enough capacity for YY IP addresses_ while updating the credentials for an existing Service Principal](#subnet-xxx-does-not-have-enough-capacity-for-yy-ip-addresses-while-updating-the-credentials-for-an-existing-service-principal)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# List the available AKS versions.
az aks get-versions --location 'location' -o 'table'

# Show the details of an AKS cluster.
az aks show -g 'resource_group_name' -n 'cluster_name'

# Get credentials for an AKS cluster.
az aks get-credentials \
  --resource-group 'resource_group_name' --name 'cluster_name'
az aks get-credentials … --overwrite-existing --admin

# Wait for the cluster to be ready.
az aks wait --created --interval 10 --timeout 1800 \
  -g 'resource_group_name' -n 'cluster_name'

# Move the cluster to its goal state *without* changing its configuration.
# Can be used to move out of a non succeeded state.
az aks update --resource-group 'resource_group_name' --name 'cluster_name' --yes

# Delete AKS clusters.
az aks delete -y -g 'resource_group_name' -n 'cluster_name'

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

# Show the details of a Feature.
az feature show -n 'AKS-ExtensionManager' --namespace 'Microsoft.ContainerService'
```

## Troubleshooting

### _Subnet XXX does not have enough capacity for YY IP addresses_ while updating the credentials for an existing Service Principal

> When you reset your cluster's credentials on an AKS cluster that uses Azure Virtual Machine Scale Sets, a Node image upgrade is performed to update your Nodes with the new credential information.

The image upgrade rollout should proceed one Node at a time unless configured differently.<br/>
Make sure you have enough space in your cluster's Subnet for at least one new Node (with all its possible containers).

## Further readings

- [Kubernetes]
- [Update or rotate the credentials for an AKS cluster]
- [Azure Service Operator]

## Sources

All the references in the [further readings] section, plus the following:

- [`az aks` command reference][az aks reference]

<!--
  References
  -->

<!-- Upstream -->
[az aks reference]: https://learn.microsoft.com/en-us/cli/azure/aks
[azure service operator]: https://azure.github.io/azure-service-operator/
[update or rotate the credentials for an aks cluster]: https://learn.microsoft.com/en-us/azure/aks/update-credentials

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[kubernetes]: ../kubernetes/README.md
