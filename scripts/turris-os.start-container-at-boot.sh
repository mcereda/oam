#!/bin/sh

cat <<EOF | tee -a '/etc/config/lxc-auto'
config container
	option name alpine
	option timeout 60
EOF
