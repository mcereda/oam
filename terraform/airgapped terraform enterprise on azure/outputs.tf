output "replicated_config_file" {
  value = {
    contents = local.replicated_config_file_contents
    path     = var.replicated_config_file_path
  }
}
output "tfe_config_file" {
  value = {
    contents = local.tfe_config_file_contents
    path     = var.tfe_config_file_path
  }
}
