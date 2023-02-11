####################
# Oracle Cloud Account
####################

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
