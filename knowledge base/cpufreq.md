# Cpufreq

Default governor is _ondemand_ for older CPUs and kernels and _schedutil_ for new CPUs and kernels.

## TL;DR

```shell
# list the available governors
cpupower frequency-info --governors

# get the current active governor
cpupower frequency-info --policy

# set a new governor
sudo cpupower frequency-set --governor performance
sudo cpupower frequency-set --governor powersave
sudo cpupower frequency-set --governor schedutil
```

## Sources

- [CPU frequency scaling]
- [CPU governer settings ignore nice load]

[cpu frequency scaling]: https://wiki.archlinux.org/title/CPU_frequency_scaling
[cpu governer settings ignore nice load]: https://forum.manjaro.org/t/cpu-governer-settings-ignore-nice-load/71476/3
