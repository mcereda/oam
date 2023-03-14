# uci

Command line utility for OpenWrt's UCI system.

## TL;DR

```sh
# Show settings.
uci show
uci show 'dhcp'

# Show what interface is the WAN.
uci show network.wan.device | cut -d "'" -f 2

# Configure a static IP address lease.
uci add dhcp host
uci set dhcp.@host[-1].name='hostname'
uci set dhcp.@host[-1].mac='11:22:33:44:55:66'
uci set dhcp.@host[-1].ip='192.168.1.2'

# Show changes to the settings.
uci changes
uci changes 'dhcp'

# Commit changes.
uci commit
uci commit 'dhcp'
```

## Further readings

- [The UCI system]

## Sources

<!-- project's references -->
[the uci system]: https://openwrt.org/docs/guide-user/base-system/uci

<!-- internal references -->
<!-- external references -->
