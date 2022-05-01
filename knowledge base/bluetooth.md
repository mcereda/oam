# Bluetooth

## Troubleshooting

### Bluetooth devices take a long time to connect

> Enabling this option will use more power.

In `/etc/bluetooth/main.conf`, under the `General` section, set `FastConnectable` to `true`:

```diff
[General]
# Permanently enables the Fast Connectable setting for adapters that
# support it. When enabled other devices can connect faster to us,
# however the tradeoff is increased power consumptions. This feature
# will fully work only on kernel version 4.1 and newer. Defaults to
# 'false'.
- #FastConnectable = true
+ FastConnectable = true
```

### Bluetooth devices cannot be used at login

In `/etc/bluetooth/main.conf`, under the `Policy` section, set `Autoenable` to `true`:

```diff
[Policy]
# AutoEnable defines option to enable all controllers when they are found.
# This includes adapters present on start as well as adapters that are plugged
# in later on. Defaults to 'false'.
- #AutoEnable = false
+ AutoEnable = true
```

## Further readings

- [Failing to use bluetooth keyboard at login]

[failing to use bluetooth keyboard at login]: https://archived.forum.manjaro.org/t/failing-to-use-bluetooth-keyboard-at-login/145056/12
