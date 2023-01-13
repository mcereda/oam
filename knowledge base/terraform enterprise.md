# Terraform Enterprise

Self-hosted distribution of Terraform Cloud.

## Basic requirements

- a license file from HashiCorp
- a TLS certificate with private key; the key and X.509 certificate must be PEM (base64) encoded
- at least 10GB of disk space on the root volume
- at least 40GB of disk space for the Docker data directory (defaults to `/var/lib/docker`)
- at least 8GB of system memory
- at least 4 CPU cores

## Further readings

- [Replicated]

## Sources

- [Terraform Enterprise documentation]

<!-- project's references -->
[terraform enterprise documentation]: https://developer.hashicorp.com/terraform/enterprise

<!-- internal references -->
[replicated]: replicated.md

<!-- external references -->
