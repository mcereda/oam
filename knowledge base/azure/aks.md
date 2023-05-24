# Azure Kubernetes Service

Managed Kubernetes solution offered by Azure.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Troubleshooting](#troubleshooting)
   1. [_Subnet XXX does not have enough capacity for YY IP addresses_ while updating the credentials for an existing Service Principal](#subnet-xxx-does-not-have-enough-capacity-for-yy-ip-addresses-while-updating-the-credentials-for-an-existing-service-principal)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

## Troubleshooting

### _Subnet XXX does not have enough capacity for YY IP addresses_ while updating the credentials for an existing Service Principal

> When you reset your cluster's credentials on an AKS cluster that uses Azure Virtual Machine Scale Sets, a Node image upgrade is performed to update your Nodes with the new credential information.

The image upgrade rollout should proceed one Node at a time unless configured differently.<br/>
Make sure you have enough space in your cluster's Subnet for at least one new Node (with all its possible containers).

## Further readings

- [Update or rotate the credentials for an AKS cluster]

## Sources

All the references in the [further readings] section, plus the following:

<!-- project's references -->
[Update or rotate the credentials for an AKS cluster]: https://learn.microsoft.com/en-us/azure/aks/update-credentials

<!-- internal references -->
[further readings]: #further-readings

<!-- external references -->
