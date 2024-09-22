#!/usr/bin/env sh

# Show pieces of configuration
uci show
uci show 'dhcp'

# Show pending changes to the settings.
uci changes
uci changes 'dhcp'

# Configure static IPv4 address leases
uci add dhcp host \
&& uci set dhcp.@host[-1].mac='11:22:33:44:55:66' \
&& uci set dhcp.@host[-1].ip='192.168.1.2' \
&& uci commit 'dhcp' \
&& service dnsmasq restart
# Configure static IPv6 address leases
uci add dhcp host \
&& uci set dhcp.@host[-1].duid='0000111122223333444455556666' \
&& uci set dhcp.@host[-1].hostid='42' \
&& uci commit 'dhcp' \
&& service dnsmasq restart

# Ignore DHCP requests from specified clients
uci add dhcp host \
&& uci set dhcp.@host[-1].mac='11:22:33:44:55:66' \
&& uci set dhcp.@host[-1].ip='ignore' \
&& uci commit 'dhcp' \
&& service dnsmasq restart
# Ignore all DHCP requests except those from known clients
# Known clients are those with static leases or listed in '/etc/ethers'
uci set dhcp.lan.dynamicdhcp='0' \
&& uci commit 'dhcp' \
&& service dnsmasq restart

# Change elements in lists.
uci set 'dhcp.@host[11].ip=192.168.1.5' \
&& uci commit 'dhcp' \
&& service dnsmasq restart

# Delete elements in lists.
uci del 'dhcp.@host[12]' \
&& uci commit 'dhcp' \
&& service dnsmasq restart
