availability_domain = "FIXME" # get it with `oci iam availability-domain list`
compartment_id      = "FIXME" # get it with `oci iam compartment list`

memory_in_gbs = 24
ocpus         = 4

# get the list of images using
# - `oci compute image list -c 'tenancy_id' --lifecycle-state 'AVAILABLE' --shape 'VM.Standard.A1.Flex'`
# - the 'oci_core_images' data source
#   see https://registry.terraform.io/providers/oracle/oci/latest/docs/data-sources/core_images
# - https://docs.oracle.com/en-us/iaas/images/
source_id = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaavmra3s4va4fqd4vlcrqc5v5jyqov5vdla3x3b6gzc64n6dkpuqua"

ssh_authorized_keys = <<-EOT
  ssh-ed25519 key-1 comment
  ssh-ed25519 key-N comment
EOT
