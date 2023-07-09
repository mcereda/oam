# uci

Command line utility for OpenWrt's UCI system.

## TL;DR

```sh
# Show settings.
uci show
uci show 'dhcp'

# Show changes to the settings.
uci changes
uci changes 'dhcp'

# Commit changes.
uci commit
uci commit 'dhcp'

# Reload the configuration
reload_config

# Show what interface is the WAN.
uci show network.wan.device | cut -d "'" -f 2

# Configure a static IP address lease.
uci add dhcp host
uci set dhcp.@host[-1].name='hostname'
uci set dhcp.@host[-1].mac='11:22:33:44:55:66'
uci set dhcp.@host[-1].ip='192.168.1.2'
uci commit 'dhcp'
reload_config

# Use a different port as WAN switching it with one in LAN.
uci set network.wan.device='lan4'
uci del_list network.br_lan.ports='lan4'
uci add_list network.br_lan.ports='eth2'
uci commit 'network'
reload_config
```

## Further readings

- [The UCI system]

## Sources

- [The UCI system]
- [Turris Omnia]

<!-- upstream -->
[the uci system]: https://openwrt.org/docs/guide-user/base-system/uci

<!-- internal references -->
[Turris Omnia]: turris.md

<!-- external references -->
