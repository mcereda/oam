# Terraform Enterprise

Self-hosted distribution of Terraform Cloud.

## Table of contents <!-- omit in toc -->

1. [Basic requirements](#basic-requirements)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## Basic requirements

- a license file from HashiCorp
- a TLS certificate with private key; the key and X.509 certificate must be PEM (base64) encoded
- at least 10GB of disk space on the root volume
- at least 40GB of disk space for the Docker data directory (defaults to `/var/lib/docker`)
- at least 8GB of system memory
- at least 4 CPU cores

## Further readings

- [Replicated]
- [`tfe-admin`][tfe-admin]

## Sources

All the references in the [further readings] section, plus the following:

- [Terraform Enterprise documentation]

<!-- upstream -->
[terraform enterprise documentation]: https://developer.hashicorp.com/terraform/enterprise

<!-- in-article references -->
[further readings]: #further-readings

<!-- internal references -->
[replicated]: replicated.md
[tfe-admin]: tfe-admin.md

<!-- external references -->
