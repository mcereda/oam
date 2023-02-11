terraform {
  required_version = "1.2.9"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "4.107.0"
    }
  }
}

####################
# Networking
####################

# See https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_vcn
resource "oci_core_vcn" "bastion" {
  compartment_id = var.compartment_id
  cidr_blocks    = var.vcn_cidr_blocks
}

# See https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet
resource "oci_core_subnet" "bastion" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.bastion.id
  cidr_block     = var.subnet_cidr_block
}

####################
# Bastion
####################

data "http" "local_ip_address" { url = "https://ifconfig.co" }
locals { local_ip_cidr = "${chomp(data.http.local_ip_address.response_body)}/32" }

# See:
# - https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/bastion_bastion
# - https://docs.oracle.com/en-us/iaas/api/#/en/bastion/20210331/Bastion/CreateBastion
resource "oci_bastion_bastion" "bastion" {
  compartment_id   = var.compartment_id
  target_subnet_id = oci_core_subnet.bastion.id

  bastion_type                 = "STANDARD" # locked
  client_cidr_block_allow_list = [local.local_ip_cidr]
}
