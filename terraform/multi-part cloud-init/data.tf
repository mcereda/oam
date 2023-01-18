# https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs
# https://github.com/chrusty/terraform-multipart-userdata/blob/master/example/cloudinit.tf

data "cloudinit_config" "azurerm_linux_virtual_machine" {
  # Disabled only to make the rendered config readable in the outputs.
  gzip          = false
  base64_encode = false

  part {
    content      = file("${path.module}/files/base.yaml")
    content_type = "text/cloud-config"
    filename     = "base"
  }

  part {
    content = templatefile(
      "${path.module}/templates/docker-ce.yaml.tftpl",
      {
        user = "azureuser"
      }
    )
    content_type = "text/cloud-config"
    merge_type   = "dict(recurse_array,no_replace)+list(append)"
    filename     = "docker"
  }
}

data "cloudinit_config" "oci_core_instance" {
  # Disabled only to make the rendered config readable in the outputs.
  gzip          = false
  base64_encode = false

  part {
    content      = file("${path.module}/files/base.yaml")
    content_type = "text/cloud-config"
    filename     = "base"
  }

  part {
    content = templatefile(
      "${path.module}/templates/docker-ce.yaml.tftpl",
      {
        user = "opc"
      }
    )
    content_type = "text/cloud-config"
    merge_type   = "dict(recurse_array,no_replace)+list(append)"
    filename     = "docker"
  }
}
