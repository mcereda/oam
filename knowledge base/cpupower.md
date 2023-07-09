# Cpupower

Default governor is _ondemand_ for older CPUs and kernels and _schedutil_ for new CPUs and kernels.

## TL;DR

```sh
# Install.
sudo dnf install kernel-tools

# List the available governors.
cpupower frequency-info --governors

# Get the current active governor.
cpupower frequency-info --policy

# Set a new governor until reboot.
sudo cpupower frequency-set -g performance
sudo cpupower frequency-set --governor powersave
sudo cpupower frequency-set --governor schedutil
```

## Further readings

- [CPU frequency scaling]

## Sources

All the references in the [further readings] section, plus the following:

- [CPU governer settings ignore nice load]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[cpu frequency scaling]: https://wiki.archlinux.org/title/CPU_frequency_scaling
[cpu governer settings ignore nice load]: https://forum.manjaro.org/t/cpu-governer-settings-ignore-nice-load/71476/3
