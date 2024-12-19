#!/usr/bin/env sh

# sources:
# - https://wiki.archlinux.org/?title=BOINC#Laptop_overheating_and_battery_duration_reduction


sudo gpasswd -a 'boinc' 'video'
xhost '+si:localuser:boinc'


# Save power.
if ( ! cpupower frequency-info --governors | grep --quiet 'ondemand' )
then
	echo "ERROR: no ondemand governor available. Aborting."
fi

sudo cpupower frequency-set --governor 'ondemand'

# Do not boost the CPU frequency for niced loads.
# The governor *must* support it - check if the file exists first.
# AMD CPUs only.
echo 1 | sudo tee '/sys/devices/system/cpu/cpufreq/ondemand/ignore_nice_load'

# Disable (1) turbo boost for Intel CPUs.
# Intel CPUs only.
echo 1 | sudo tee '/sys/devices/system/cpu/intel_pstate/no_turbo'


sudo systemctl start 'boinc-client.service'


# Open `boinc-manager` with*out* also starting the client (`-nd`).
# Connect to the instance started by the current system (`-a`).
# Allow for multiple instances of the manager (`-m`).
# Provide the connection password in the command (`-p`).
boinc-manager -nd -amp '123'
