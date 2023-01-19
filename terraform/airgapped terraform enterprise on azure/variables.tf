variable "replicated_config_file_location" {
  type        = string
  default     = "/etc/replicated.conf"
  description = "Only read on initial startup."
}
variable "replicated_config_license_bootstrap_airgap_package_path" {
  type = string
}
variable "replicated_config_license_file_location" {
  type    = string
  default = "/etc/license.rli"
}

variable "tfe_config_file_location" {
  type    = string
  default = "/etc/settings.conf"
}
