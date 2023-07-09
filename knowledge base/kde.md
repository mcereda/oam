# KDE

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Prioritize a WiFi network connection](#prioritize-a-wifi-network-connection)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Get from '~/.config/kinfocenterrc' the current value for the 'MenuBar' key in
# the 'MainWindow' group.
kreadconfig5 --file kinfocenterrc --group MainWindow --key MenuBar

# Set into '~/.config/kdeglobals' a new value for the 'Show hidden files' key in
# the 'KFileDialog Settings' group.
kwriteconfig5 --file kdeglobals --group 'KFileDialog Settings' \
  --key 'Show hidden files' --type bool true
```

## Prioritize a WiFi network connection

Plasma-nm lets you change a network's priority specifying a number in the network's _General configuration_ tab. Higher numbers set a higher priority.

## Further readings

- [KDE Configuration Files]

[kde configuration files]: https://userbase.kde.org/KDE_System_Administration/Configuration_Files

## Sources

All the references in the [further readings] section, plus the following:

- [Gsettings-like tools for KDE]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[gsettings-like tools for kde]: https://askubuntu.com/questions/839647/gsettings-like-tools-for-kde
