#!/usr/bin/env sh

# Create alpine-based containers.
lxc-create -n 'alpine' -t 'download' -- -d 'Alpine' -r '3.18' -a 'armv7l'

# Set static leases.
uci add dhcp 'host'
uci set dhcp.@host[-1].name='alpine'
uci set dhcp.@host[-1].mac="$(grep 'hwaddr' '/srv/lxc/alpine/config' | sed 's/.*= //')"
uci set dhcp.@host[-1].ip='192.168.111.2'
uci commit 'dhcp'
reload_config
luci-reload

# Start containers at boot.
cat <<EOF | tee -a '/etc/config/lxc-auto'
config container
	option name alpine
	option timeout 60
EOF


##
# Example: Gitea container
##

lxc-create -n 'gitea' -t 'download' -- -d 'Gentoo' -r 'openrc' -a 'armv7l'
uci add dhcp 'host'
uci set dhcp.@host[-1].name='gitea'
uci set dhcp.@host[-1].mac="$(grep 'hwaddr' '/srv/lxc/gitea/config' | sed 's/.*= //')"
uci set dhcp.@host[-1].ip='192.168.111.252'
uci commit 'dhcp'
reload_config
luci-reload
cat <<EOF | tee -a '/etc/config/lxc-auto'
config container
	option name gitea
	option timeout 60
EOF
lxc-start 'gitea'
lxc-attach 'gitea'
uci del 'dhcp.@host[12]'
uci commit 'dhcp'
reload_config
luci-reload
