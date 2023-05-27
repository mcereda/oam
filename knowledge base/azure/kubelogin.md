# Azure Kubelogin

Client-go credential (exec) plugin for `kubectl` 1.11+ implementing Azure authentication.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Installation.
brew install 'Azure/kubelogin/kubelogin'


# Leverage the already logged-in context used by Azure CLI.
# The token will be issued in the same Azure AD tenant as in `az login` and be
# managed by the Azure CLI.
kubelogin convert-kubeconfig -l 'azurecli'


# Use service principals to login.
# The token will **not** be cached on the filesystem.
# Only works with managed AAD.
# The service principal can be member of up to 200 AAD groups.

# Provide password-based credentials via command flags.
kubelogin convert-kubeconfig -l 'spn' \
  --client-id 'spn_client_id' --client-secret 'spn_client_secret'

# Provide password-based credentials via environment variables.
kubelogin convert-kubeconfig -l 'spn' && export \
  AAD_SERVICE_PRINCIPAL_CLIENT_ID='spn_client_id' \
  AAD_SERVICE_PRINCIPAL_CLIENT_SECRET='spn secret'
kubelogin convert-kubeconfig -l 'spn' && export \
  AZURE_CLIENT_ID='spn_client_id' AZURE_CLIENT_SECRET='spn secret'

# Provide pfx client certificate-based credentials via environment variables.
kubelogin convert-kubeconfig -l 'spn' && export \
  AAD_SERVICE_PRINCIPAL_CLIENT_ID='spn_client_id' \
  AAD_SERVICE_PRINCIPAL_CLIENT_CERTIFICATE='path/to/cert.pfx' \
  AAD_SERVICE_PRINCIPAL_CLIENT_CERTIFICATE_PASSWORD='pfx_password'
kubelogin convert-kubeconfig -l 'spn' && export \
  AZURE_CLIENT_ID='spn_client_id' \
  AZURE_CLIENT_CERTIFICATE_PATH='path/to/cert.pfx' \
  AZURE_CLIENT_CERTIFICATE_PASSWORD='pfx_password'


# Use managed identities to login.
# The token will **not** be cached on the filesystem.
kubelogin convert-kubeconfig -l 'msi'
kubelogin convert-kubeconfig -l 'msi' --client-id 'msi_client_id'


# Use workload identities to login.
# The token will **not** be cached on the filesystem.
export \
  AZURE_CLIENT_ID='applicationId_federated_with_workload_identity' \
  AZURE_TENANT_ID='tenantId' \
  AZURE_FEDERATED_TOKEN_FILE='file_containing_the_signed_assertion_of_workload_identity' \
  AZURE_AUTHORITY_HOST='base_url_of_an_azure_active_directory_authority' \
&& kubelogin convert-kubeconfig -l 'workloadidentity'


# Remove cached tokens.
kubelogin remove-tokens
```

## Further readings

- [Website]
- [Azure CLI]
- [`kubectl`][kubectl]

<!-- project's references -->
[website]: https://azure.github.io/kubelogin/

<!-- in-article references -->
<!-- internal references -->
[azure cli]: cli.md
[kubectl]: ../kubernetes/kubectl.md

<!-- external references -->
