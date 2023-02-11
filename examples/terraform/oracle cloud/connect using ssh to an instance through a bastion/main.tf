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
resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_id
  cidr_blocks    = var.vcn_cidr_blocks
}

# See https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet
resource "oci_core_subnet" "subnet" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
  cidr_block     = var.subnet_cidr_block
}

# See https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_nat_gateway
resource "oci_core_nat_gateway" "nat_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id
}

# See https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_route_table
resource "oci_core_route_table" "route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vcn.id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.nat_gateway.id
  }
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
  target_subnet_id = oci_core_subnet.subnet.id

  bastion_type                 = "STANDARD" # locked
  client_cidr_block_allow_list = [local.local_ip_cidr]
}

resource "oci_bastion_session" "ssh_port_forwarding" {
  bastion_id = oci_bastion_bastion.bastion.id

  key_details {
    public_key_content = var.ssh_authorized_key
  }

  target_resource_details {
    session_type         = "PORT_FORWARDING"
    target_resource_id   = oci_core_instance.instance.id
    target_resource_port = 22
  }
}

####################
# Instance
####################

# See https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance
resource "oci_core_instance" "instance" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  shape               = var.shape

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_key
  }

  agent_config {
    plugins_config {
      name          = "Bastion"
      desired_state = "ENABLED"
    }
  }

  create_vnic_details {
    subnet_id = oci_core_subnet.subnet.id
  }

  shape_config {
    memory_in_gbs = var.memory_in_gbs
    ocpus         = var.ocpus
  }

  source_details {
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    source_id               = var.source_id
    source_type             = var.source_type
  }
}
