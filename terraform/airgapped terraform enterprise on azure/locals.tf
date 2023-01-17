locals {
  # See https://help.replicated.com/docs/native/customer-installations/automating/#configure-replicated-automatically
  replicated_config = {}

  # Replicated's settings file is JSON formatted.
  # See https://help.replicated.com/docs/native/customer-installations/automating
  replicated_config_file_contents = jsonencode(local.replicated_config)

  # See https://developer.hashicorp.com/terraform/enterprise/install/automated/automating-the-installer#available-settings
  tfe_config = {
    hostname     = "hostname"
    enc_password = "password"
  }

  # TFE's settings file is JSON formatted.
  # All defined keys must be objects with the 'value' key in it. (ノಠ益ಠ)ノ彡┻━┻
  # All values must be strings.
  # See https://developer.hashicorp.com/terraform/enterprise/install/automated/automating-the-installer#format
  tfe_config_file_contents = jsonencode({ for k, v in local.tfe_config : k => { "value" : tostring(v) } })
}
