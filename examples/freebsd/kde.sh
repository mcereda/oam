#!/usr/bin/env sh

set -e

if [ "$(id -ru)" -eq 0 ]
then
	echo "Run this again as 'root'"
	exit 1
fi

# KDE
# Add 'xf86-video-vmware' if in VirtualBox

pw groupmod 'video' -m 'username'
pkg install 'xorg' 'sddm' 'plasma5-plasma' 'plasma5-sddm-kcm' 'konsole' 'dolphin-plugins'
sysctl net.local.stream.recvspace=65536 net.local.stream.sendspace=65536
sysrc dbus_enable="YES" sddm_enable="YES"
service 'dbus' start
service 'sddm' start
