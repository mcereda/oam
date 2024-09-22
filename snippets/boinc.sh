#!/usr/bin/env sh

# sources:
# - https://wiki.archlinux.org/?title=BOINC#Laptop_overheating_and_battery_duration_reduction

if ( ! cpupower frequency-info --governors | grep --quiet ondemand )
then
	echo "ERROR: no ondemand governor available. Aborting."
fi

sudo gpasswd -a boinc video
xhost si:localuser:boinc

sudo cpupower frequency-set --governor ondemand

# Do not boost the CPU frequency for niced loads.
# The governor must support it - check if the file exists.
# Usually AMD only
echo 1 | sudo tee '/sys/devices/system/cpu/cpufreq/ondemand/ignore_nice_load'

# Disable (1) turbo boost for Intel CPUs.
echo 1 | sudo tee '/sys/devices/system/cpu/intel_pstate/no_turbo'

sudo systemctl start boinc-client.service
