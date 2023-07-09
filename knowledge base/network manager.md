# Network Manager

## Table of contents <!-- omit in toc -->

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
```

## Sources

- [Website]
- [NM-settings]

<!--
  References
  -->

<!-- Upstream -->
[website]: https://networkmanager.dev/

<!-- Others -->
[nm-settings]: https://people.freedesktop.org/~lkundrak/nm-docs/nm-settings.html
