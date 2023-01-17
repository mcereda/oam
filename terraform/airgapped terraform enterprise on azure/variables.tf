variable "replicated_config_file_path" {
  default     = "/etc/replicated.conf"
  description = "Only read on initial startup."
}
variable "tfe_config_file_path" {
  default = "/etc/ptfe.settings.json"
}
