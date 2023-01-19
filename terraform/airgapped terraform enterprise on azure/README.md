# Airgapped Terraform Enterprise on Azure

> In progress and absolutely, totally **not** ready for use.

Stateless active/active.

1. [Requirements](#requirements)
2. [Sources](#sources)

## Requirements

| Requirement             | Description                                                                                                                                        |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| Passwords               | All passwords must be stored as a Base64 encoded secret in Azure Key Vault and retrieved during runtime.                                           |
| Replicated license file | A valid Replicated license file (`.rli`) must be stored as a Base64 encoded secret in Azure Key Vault and retrieved during runtime.                |
| TFE airgap bundle       | The TFE airgap bundle for Replicated must be stored as a Blob in a Storage Account and retrieved by the VM after first boot.                       |
| TLS certificate         | The TLS certificate and private key files must be PEM-encoded. The TLS certificate file can contain a full chain of TLS certificates if necessary. |
| Tokens                  | All tokens must be stored as a Base64 encoded secret in Azure Key Vault and retrieved during runtime.                                              |
| Virtual machine         | Must be a Linux VM.                                                                                                                                |

![requirements diagram]

## Sources

- [Terraform Enterprise]
- [Automated installations] of Replicated
- Hashicorp's [Terraform Enterprise Azure Module][hashicorp/terraform-azurerm-terraform-enterprise] on GitHub
- Azure's [Terraform Enterprise Azure Instance Module][azure-terraform/terraform-azurerm-terraform-enterprise-instance] on GitHub

<!-- knowledge base -->
[requirements diagram]: design/requirements.png

<!-- hashicorp references -->
[terraform enterprise]: https://developer.hashicorp.com/terraform/enterprise

<!-- replicated references -->
[automated installations]: https://help.replicated.com/docs/native/customer-installations/automating/

<!-- repositories -->
[azure-terraform/terraform-azurerm-terraform-enterprise-instance]: https://github.com/Azure-Terraform/terraform-azurerm-terraform-enterprise-instance
[hashicorp/terraform-azurerm-terraform-enterprise]: https://github.com/hashicorp/terraform-azurerm-terraform-enterprise
