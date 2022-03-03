#!/bin/sh

# sources:
# - https://wiki.archlinux.org/?title=BOINC#Laptop_overheating_and_battery_duration_reduction

if ( ! cpupower frequency-info --governors | grep --quiet ondemand )
then
	echo "ERROR: no ondemand governor available. Aborting."
fi

sudo gpasswd -a boinc video
xhost si:localuser:boinc

sudo cpupower frequency-set --governor ondemand
echo 1 | sudo tee /sys/devices/system/cpu/cpufreq/ondemand/ignore_nice_load
sudo systemctl start boinc-client.service
