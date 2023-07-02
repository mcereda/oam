terraform {
  required_version = "1.2.9"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "4.107.0"
    }
  }
}

resource "oci_core_vcn" "default" {
  # https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_vcn
  compartment_id = var.compartment_id
  cidr_blocks    = ["10.0.0.0/16"]
}

resource "oci_core_subnet" "default" {
  # https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.default.id
  cidr_block     = "10.0.0.0/24"
}

# To be able to connect to the instance from the Internet, one needs to create a
# route table with the default route 0.0.0.0/0 pointing to an internet gateway,
# and associate the subnet to it.

resource "oci_core_internet_gateway" "default" {
  # https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_internet_gateway
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.default.id
}
resource "oci_core_route_table" "default" {
  # https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_route_table
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.default.id

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.default.id
  }
}
resource "oci_core_route_table_attachment" "default" {
  # See https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_route_table_attachment
  subnet_id      = oci_core_subnet.default.id
  route_table_id = oci_core_route_table.default.id
}

data "oci_core_images" "available" {
  # https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_images
  compartment_id = var.compartment_id
  operating_system = var.operating_system
  operating_system_version = var.operating_system_version
  shape = var.shape
  state = "AVAILABLE"
  sort_by = "DISPLAYNAME"
  sort_order = "DESC"
}

resource "oci_core_instance" "this" {
  # https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance
  compartment_id      = var.compartment_id
  availability_domain = var.availability_domain
  shape               = var.shape

  create_vnic_details {
    subnet_id = oci_core_subnet.default.id
  }

  extended_metadata = {}
  metadata = {
    ssh_authorized_keys = var.ssh_authorized_keys
  }

  shape_config {
    memory_in_gbs = var.memory_in_gbs
    ocpus         = var.ocpus
  }

  source_details {
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    source_id               = coalesce(var.source_id, data.oci_core_images.available.images[0].id)
    source_type             = var.source_type
  }

  lifecycle {
    ignore_changes = [
      # avoid recreating the instance when an updated source image is found.
      source_details["source_id"]
    ]
  }
}
