# Network Manager

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Get all settings of a connection.
nmcli connection show 'Wired connection 1'

# Change the autoconnect priority setting of a connection.
# Higher numbers set a higher priority.
nmcli connection modify 'it hurts when ip' connection.autoconnect-priority 1

# Start the TUI.
nmtui

# Show networks' channel, transfer rate, signal strength and security.
nmcli device wifi list
nmcli dev wifi
```

## Sources

- [Website]
- [NM-settings]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[website]: https://networkmanager.dev/

<!-- Others -->
[nm-settings]: https://people.freedesktop.org/~lkundrak/nm-docs/nm-settings.html
