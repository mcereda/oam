# Set the _ondemand_ CPU governor to not rise the frequencies for niced loads

## TL:DR

```sh
sudo cpupower frequency-set --governor ondemand
echo 1 | sudo tee /sys/devices/system/cpu/cpufreq/ondemand/ignore_nice_load

# set this on boot
echo "w /sys/devices/system/cpu/cpufreq/ondemand/ignore_nice_load - - - - 1" | sudo tee /etc/tmpfiles.d/ondemand-ignore-nice.conf
```

## Further readings

- [Cpufreq]
- [Laptop overheating and battery duration reduction]

[cpufreq]: cpufreq.md

[laptop overheating and battery duration reduction]: https://wiki.archlinux.org/?title=BOINC#Laptop_overheating_and_battery_duration_reduction
