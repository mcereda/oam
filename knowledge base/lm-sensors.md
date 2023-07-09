# LM-sensors

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Install.
sudo dnf install lm_sensors

# Detect and generate a list of kernel modules.
# Needs to be executed prior of the next commands.
sudo sensors-detect

# Show the current readings of all sensors.
sensors

# Display sensor information in raw output.
# Suitable for parsing.
sensors -u

# Show temperatures in degrees Fahrenheit.
sensors -f
sensors --fahrenheit
```

## Sources

- [cheat.sh]
- [archlinux wiki]
- [How to Install lm Sensors on Linux]

<!--
  References
  -->

<!-- Others -->
[archlinux wiki]: https://wiki.archlinux.org/title/lm_sensors
[cheat.sh]: https://cheat.sh/sensors
[how to install lm sensors on linux]: https://linoxide.com/install-lm-sensors-linux/
