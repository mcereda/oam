# Hashicorp Vault

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Install the CLI.
brew tap hashicorp/tap && brew install hashicorp/tap/vault

# Settings.
export VAULT_ADDR='https://vault.address/'
export VAULT_NAMESPACE='namespace_name'

# Check the connection to the Vault server.
vault status

# Login.
vault login
vault login -method='oidc'

# Unwrap a token.
# This operation may only be attempted once; after this attempt, the token will
# die and will need to be regenerated.
export VAULT_TOKEN='s.WVDAitOTTTfcjlklwk8AADDs' && vault unwrap

# Create a secret.
vault kv put secret/demo-app/config username='foo' password='bar'

# Get a secret.
# Note: "data" need to be added here in the path (secret/demo-app/config), as
# it is a property of the Vault API.
vault read -format 'json' 'secret/data/demo-app/config'
```

## Further readings

- [HashiCorp Vault]

<!--
  References
  -->

<!-- Upstream -->
[hashicorp vault]: https://www.vaultproject.io/
