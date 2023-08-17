#!/bin/sh

lxc-create -n 'alpine' -t 'download' -- -d 'Alpine' -r '3.18' -a 'armv7l'

uci add dhcp host
uci set dhcp.@host[-1].name='alpine'
uci set dhcp.@host[-1].mac="$(grep 'hwaddr' '/srv/lxc/alpine/config' | sed 's/.*= //')"
uci set dhcp.@host[-1].ip='192.168.111.2'
uci commit 'dhcp'
reload_config
luci-reload
