# tlp

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

Manual mode: changes to the power source will be ignored until the next reboot, or until the `tlp start` command is issued to resume automatic mode.

Changes through commands are valid until next reboot.

```sh
# Install it.
zypper install 'tlp' 'tlp-rdw'

# Start the service.
sudo tlp start
sudo systemctl start 'tlp.service'

# Show information about the system.
sudo tlp-stat

# Show information about the CPU only.
# Includes the active scaling driver and available governors.
sudo tlp-stat -p
sudo tlp-stat --processor -v

# Show information about the battery only.
sudo tlp-stat -b
sudo tlp-stat --battery

# Show the service's status.
tlp-stat -s
tlp-stat --system

# Show the active configuration.
tlp-stat -c
tlp-stat --config

# Show differences between the defaults and the user configuration.
# From version 1.4.
tlp-stat --cdiff

# Apply profiles.
# Doing this enters manual mode.
sudo tlp bat
sudo tlp ac

# Change battery charge thresholds.
sudo tlp setcharge '70' '90' 'BAT0'

# Restore battery charge thresholds.
sudo tlp setcharge

# Check, enable, or disable automatic, event based actions on radio devices.
# Leverages the Radio Device Wizard.
tlp-rdw
tlp-rdw enable
tlp-rdw disable
```

## Further readings

- [Documentation]
- [`cpupower`][cpupower]

## Sources

All the references in the [further readings] section, plus the following:

- [Battery care vendor specifics]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[cpupower]: cpupower.md

<!-- Upstream -->
[battery care vendor specifics]: https://linrunner.de/tlp/settings/bc-vendors.html
[documentation]: https://linrunner.de/tlp/index.html

<!-- Others -->
