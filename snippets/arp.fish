#!/usr/bin/fish

###
# Linux
# ------------------
###

# Display the current entries
arp
arp --numeric

# Answer requests for 10.0.0.2 on eth0 with the MAC address for eth1
arp --device 'eth0' --use-device -s '10.0.0.2' 'eth1' 'pub'
arp -i eth0 -Ds 10.0.0.2 eth1 pub

# Delete the ARP table entry for 10.0.0.1 on interface eth1
# Will match published proxy ARP entries *and* permanent entries
arp -i 'eth1' -d '10.0.0.1'


###
# Mac OS X
# ------------------
###

# Display the current entries
arp -a

# Delete entries
arp -d -a
arp -d -i 'en0' 'nas.lan'
