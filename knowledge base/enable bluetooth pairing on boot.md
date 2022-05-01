# Enable Bluetooth pairing on boot

> Bluetooth pairing on boot is enabled by default on Mac OS X, at least for Apple devices.

On GNU/Linux:

1. enable the `bluetooth` service on boot
1. make sure the `AutoEnable` option in `/etc/bluetooth/main.conf` is set to `true`
1. [optional] make sure the `FastConnectable` option in `/etc/bluetooth/main.conf` is set to `true`

## Further readings:

[bluetooth]: bluetooth.md
