variable "availability_domain" {
  type = string
}
variable "compartment_id" {
  type = string
}
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

variable "ssh_authorized_keys" {
  type = string
}
