#!/usr/bin/env sh

if [ "$(id -ru)" -eq 0 ]
then
	echo "Run this again as 'root'"
	exit 1
fi

# Package management
# Use 'virtualbox-ose-additions-nox11' for console-only systems.

pkg bootstrap
pkg update
pkg install -y 'virtualbox-ose-additions'

# Start VirtualBox services at boot

sysrc vboxguest_enable="YES"
sysrc vboxservice_enable="YES"

# NTP workaround
# Needed if NTP or NTPDate are used

sysrc vboxservice_flags="--disable-timesync"
