# See:
# - https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs
# - https://github.com/chrusty/terraform-multipart-userdata/blob/master/example/cloudinit.tf

data "cloudinit_config" "user_data" {
  # Disabled only to make the rendered config readable in the outputs.
  gzip          = false
  base64_encode = false

  part {
    content = templatefile(
      "${path.module}/templates/cloud-init/docker-ce.yaml.tftpl",
      {
        docker_user = "azureuser"
      }
    )
    content_type = "text/cloud-config"
    filename     = "docker-ce"
  }

  part {
    content = templatefile(
      "${path.module}/templates/cloud-init/tfe.yaml.tftpl",
      {
        replicated_config_file_location             = var.replicated_config_file_location
        replicated_config_file_contents_b64encoded  = base64encode(local.replicated_config_file_contents)
        replicated_license_file_location            = var.replicated_config_license_file_location
        replicated_license_file_contents_b64encoded = base64encode("") # FIXME: get from Key Vault
        tfe_config_file_location                    = var.tfe_config_file_location
        tfe_config_file_contents_b64encoded         = base64encode(local.tfe_config_file_contents)
      }
    )
    content_type = "text/cloud-config"
    merge_type   = "dict(recurse_array,no_replace)+list(append)"
    filename     = "tfe"
  }
}
