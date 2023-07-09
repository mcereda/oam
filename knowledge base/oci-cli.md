# OCI CLI

Oracle Cloud Infrastructure CLI.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Install the CLI.
brew install 'oci-cli'

# Start the interactive setup.
oci setup config

# Generate a key pair to include in the config file.
oci setup keys

# Show the current configuration.
cat ~/.oci/config

# List available compartments.
oci iam compartment list
oci iam compartment list -c 'tenancy_id'

# Create compartments.
oci iam compartment create -c 'root_compartment_id' \
  --name 'compartment_name' --description 'friendly_description'

# List available availability domains.
oci iam availability-domain list
oci iam availability-domain list -c 'tenancy_id'

# List available compute images.
# Output is paginated.
oci compute image list -c 'tenancy_id' --all
oci compute image list -c 'tenancy_id' \
  --lifecycle-state 'AVAILABLE' --shape 'VM.Standard.A1.Flex' \
  --operating-system 'Oracle Linux' --operating-system-version '8' \
  --sort-by 'DISPLAYNAME' --sort-order 'DESC'

# List available compute instance plugins.
# Requires to be given the OS and its version.
oci instance-agent available-plugins get -c 'tenancy_id' \
  --os-name 'Oracle Linux' --os-version '8'

# List existing compute instances.
oci compute instance list -c 'tenancy_id'
```

## Configuration

| Unix location            | Description                                                                            |
| ------------------------ | -------------------------------------------------------------------------------------- |
| `~/.oci/config`          | The default configuration file.                                                        |
| `~/.oci/oci_api_key.pem` | Full path and filename of the private key. The key pair **must be in the PEM format**. |

## Further readings

- [Command Line Interface]
- [SDK and CLI Configuration File]
- [Required keys and OCIDs]

<!--
  References
  -->

<!-- Upstream -->
[command line interface]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm
[required keys and ocids]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/apisigningkey.htm
[sdk and cli configuration file]: https://docs.oracle.com/en-us/iaas/Content/API/Concepts/sdkconfig.htm
