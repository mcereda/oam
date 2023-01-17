# See https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_vcn
resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.0.0.0/16"]
}

# See https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet
resource "oci_core_subnet" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
  cidr_block     = "10.0.0.0/24"
}

# Needed to be able to connect to the instance from the Internet.
# Need to create a route table with the default route 0.0.0.0/0 pointing to the
# internet gateway, and associate the subnet to it.
# See https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_internet_gateway
resource "oci_core_internet_gateway" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id
}
resource "oci_core_route_table" "this" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.this.id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.this.id
  }
}
resource "oci_core_route_table_attachment" "this" {
  subnet_id      = oci_core_subnet.this.id
  route_table_id = oci_core_route_table.this.id
}

# See https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance
resource "oci_core_instance" "this" {
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  shape               = var.shape

  create_vnic_details {
    subnet_id = oci_core_subnet.this.id
  }

  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
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
