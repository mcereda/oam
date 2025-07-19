#!/usr/bin/fish

###
# Linux
# ------------------
###

# Display the contents of the current routing table
route
route -n

# Add routes
route add -net '192.56.76.0' netmask '255.255.255.0' metric '1024' dev 'eth0'
route add -net '192.57.66.0' netmask '255.255.255.0' gw 'astro'
route add -net '224.0.0.0' netmask '240.0.0.0' dev 'eth1'
route -6  add '2001:0002::/48' metric '1' dev 'eth2'

# Add default routes
# Default routes will be used when no other route matches
# The gateway *must* be be on a directly reachable route
route add 'default' gw 'dijkstra'
route add 'default' gw '192.168.100.1'

# Delete routes
# Since the Linux routing kernel uses classless addressing, one pretty much always has to specify the netmask as seen in
# 'route -n'
route del -net '192.56.76.0' netmask '255.255.255.0'

# Delete the current default route
# It is either labeled 'default' or has '0.0.0.0' in the destination field of the current routing table
route del 'default'


###
# Mac OS X
# ------------------
###

# Flush the routing tables of all or specified gateway entries
route flush
route -n flush -inet6
