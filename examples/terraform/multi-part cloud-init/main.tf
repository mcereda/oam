# resource "azurerm_linux_virtual_machine" "vm" {
#   user_data = data.cloudinit_config.azurerm_linux_virtual_machine.rendered
#   …
# }

# resource "oci_core_instance" "instance" {
#   …
#   metadata = {
#     …
#     user_data = data.cloudinit_config.oci_core_instance.rendered
#   }
# }
