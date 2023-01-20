output "replicated_config_file" {
  value = {
    contents = local.replicated_config_file_contents
    location = var.replicated_config_file_location
  }
}
output "tfe_config_file" {
  value = {
    contents = local.tfe_config_file_contents
    location = var.tfe_config_file_location
  }
}

output "cloudinit_config" {
  value = data.cloudinit_config.user_data.rendered
}
