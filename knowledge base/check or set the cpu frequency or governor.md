# Check or set the CPU frequency or governor

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Check what governors are available.
cat '/sys/devices/system/cpu/cpufreq/'*'/scaling_available_governors'

# Get the current active governor.
cat '/sys/devices/system/cpu/cpufreq/policy0/scaling_governor'
cat '/sys/devices/system/cpu/cpufreq/'*'/scaling_governor'

# List the active CPUs affected by the current governor.
cat '/sys/devices/system/cpu/cpufreq/'*'/affected_cpus'

# Enable new governors.
echo 'schedutil' | sudo tee '/sys/devices/system/cpu/cpufreq/policy0/scaling_governor'
echo 'powersave' | sudo tee '/sys/devices/system/cpu/cpufreq/policy1/scaling_governor'

# Get the current frequency of CPUs.
cat '/sys/devices/system/cpu/cpufreq/policy0/scaling_cur_freq'
cat '/sys/devices/system/cpu/cpufreq/'*'/scaling_cur_freq'

# Do not boost the CPU frequency for niced loads.
# The governor must support it - check if the file exists.
echo 1 | sudo tee '/sys/devices/system/cpu/cpufreq/ondemand/ignore_nice_load'

# Disable (1) or enable (0) turbo boost for Intel CPUs.
echo 1 | sudo tee '/sys/devices/system/cpu/intel_pstate/no_turbo'

# Check what energy vs performance hint are available for CPUs.
cat '/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_available_preferences'

# Get the current energy vs performance hint used by CPUs.
cat '/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference'
cat '/sys/devices/system/cpu/cpu'*'/cpufreq/energy_performance_preference'

# Set energy vs performance hints.
echo 'balance_performance' | sudo tee '/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference'
echo 'power' | sudo tee '/sys/devices/system/cpu/cpu'*'/cpufreq/energy_performance_preference'
```

## Further readings

- [`cpupower`][cpupower]
- [Set the _ondemand_ CPU governor to not rise the frequencies for niced loads][set the ondemand cpu governor to not rise the frequencies for niced loads]

## Sources

All the references in the [further readings] section, plus the following:

- [CPU performance scaling]
- The [*intel_pstate* CPU performance scaling driver][intel_pstate cpu performance scaling driver]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[cpupower]: cpupower.md
[set the ondemand cpu governor to not rise the frequencies for niced loads]: set%20the%20ondemand%20cpu%20governor%20to%20not%20rise%20the%20frequencies%20for%20niced%20loads.md
[tlp]: tlp.md

<!-- Upstream -->
[cpu performance scaling]: https://www.kernel.org/doc/html/latest/admin-guide/pm/cpufreq.html
[intel_pstate cpu performance scaling driver]: https://www.kernel.org/doc/html/next/admin-guide/pm/intel_pstate.html
