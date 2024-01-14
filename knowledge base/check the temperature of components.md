# Check the temperature of components

## TL;DR

```sh
# Show the current temperature of thermal zones in millidegrees C.
cat '/sys/class/thermal/thermal_zone'*'/temp'

# Show the current temperature of the CPU package in millidegrees C.
grep 'x86_pkg_temp' '/sys/class/thermal/thermal_zone'*'/type' | cut -d':' -f1 | xargs dirname | xargs -I{} cat {}'/temp'

# Show all types with relative temperature in degrees C.
paste <(cat /sys/class/thermal/thermal_zone*/type) <(cat /sys/class/thermal/thermal_zone*/temp) \
| column -s $'\t' -t | sed 's/\(.\)..$/.\1°C/'
```

See [lm-sensors], [hddtemp] or [nvme-cli] for better ways.

## Sources

- [How to check CPU temperature on Ubuntu Linux]
- [Find out CPU temperature from the command-line]

<!--
  References
  -->

<!-- Knowledge base -->
[lm-sensors]: lm-sensors.md
[nvme-cli]: nvme-cli.md

<!-- Others -->
[find out cpu temperature from the command-line]: https://www.baeldung.com/linux/cpu-temperature
[hddtemp]: https://wiki.archlinux.org/title/Hddtemp
[how to check cpu temperature on ubuntu linux]: https://www.cyberciti.biz/faq/how-to-check-cpu-temperature-on-ubuntu-linux/
