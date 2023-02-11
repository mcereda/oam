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
# Networking
####################

variable "vcn_cidr_blocks" {
  type = list(string)
  default = [
    "10.0.0.0/16"
  ]
}
variable "subnet_cidr_block" {
  type    = string
  default = "10.0.0.0/24"
}

####################
# Common
####################

variable "ssh_authorized_key" {
  type = string
}

####################
# Instance
####################

variable "shape" {
  type    = string
  default = "VM.Standard.A1.Flex"
}

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
variable "source_id" {
  type = string
}
variable "source_type" {
  type    = string
  default = "image"
}
