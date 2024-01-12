# Cpupower

Default governor is _ondemand_ for older CPUs and kernels and _schedutil_ for new CPUs and kernels.

## TL;DR

```sh
# Install.
apt install 'linux-cpupower'
dnf install 'kernel-tools'
zypper install 'cpupower'

# List the available governors.
cpupower frequency-info --governors
cpupower -c "3-6" frequency-info --governors
cpupower --cpu "0-$(( $(nproc) - 1 ))" frequency-info --governors

# Get the current active governor.
cpupower frequency-info --policy
cpupower -c '4' frequency-info --policy
cpupower --cpu '4,5' frequency-info --policy

# Set new governors until reboot.
sudo cpupower frequency-set -g 'performance'
sudo cpupower -c '1' frequency-set --governor 'powersave'
sudo cpupower --cpu '2,4,7' frequency-set --governor 'schedutil'

# Get the current frequency of CPUs.
cpupower frequency-info -f
cpupower -c '4-7' frequency-info -fm
cpupower --cpu '2,5' frequency-info --freq --human
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
