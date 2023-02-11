####################
# Debug
####################

# output "local_ip_address" { value = data.http.local_ip_address }
# output "local_ip_cidr" { value = local.local_ip_cidr }

####################
# Bastion
####################

output "bastion" { value = oci_bastion_bastion.bastion }
