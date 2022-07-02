# Network Manager

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

- [nm-settings]

[nm-settings]: https://people.freedesktop.org/~lkundrak/nm-docs/nm-settings.html
