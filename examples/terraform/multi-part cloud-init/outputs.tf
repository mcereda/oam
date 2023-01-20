output "cloudinit_config_azurerm_linux_virtual_machine" {
  value = data.cloudinit_config.azurerm_linux_virtual_machine.rendered
}

output "cloudinit_config_oci_core_instance" {
  value = data.cloudinit_config.oci_core_instance.rendered
}
