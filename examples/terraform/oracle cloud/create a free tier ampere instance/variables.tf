####################
# Oracle Cloud Account
####################

variable "availability_domain" {
  type = string
}
variable "compartment_id" {
  type = string
}

####################
# Instance
####################

variable "memory_in_gbs" {
  type    = number
  default = 24
}
variable "ocpus" {
  type    = number
  default = 4
}

variable "boot_volume_size_in_gbs" {
  type    = number
  default = 50
}
variable "operating_system" {
  type = string
  default = "Oracle Linux"
}
variable "operating_system_version" {
  type = number
  default = 9
}
variable "shape" {
  type = string
  default = "VM.Standard.A1.Flex"
}
variable "source_id" {
  type = string
  default = null
}
variable "source_type" {
  type    = string
  default = "image"
}

variable "ssh_authorized_keys" {
  type = string
}
