# The `uci` command

Command line utility for OpenWrt's UCI system.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Show settings.
uci show
uci show 'dhcp'

# Show what interface is the WAN.
uci show network.wan.device | cut -d "'" -f 2

# Configure static IP address leases.
uci add dhcp host
uci set dhcp.@host[-1].name='hostname'
uci set dhcp.@host[-1].mac='11:22:33:44:55:66'
uci set dhcp.@host[-1].ip='192.168.1.2'
uci commit 'dhcp'
reload_config

# Delete list elements.
uci del 'dhcp.@host[12]'
uci commit 'dhcp'
reload_config

# Use a different port as WAN by swapping the default one with another one in LAN.
uci set network.wan.device='lan4'
uci del_list network.br_lan.ports='lan4'
uci add_list network.br_lan.ports='eth2'
uci commit 'network'
reload_config

# Show pending changes to the settings.
uci changes
uci changes 'dhcp'

# Commit pending changes.
uci commit
uci commit 'dhcp'

# Discard pending changes.
uci revert 'dhcp.cfg19fe63'

# Reload the configuration
reload_config
```

## Further readings

- [The UCI system]

## Sources

- [The UCI system]
- [Turris Omnia]

<!--
  References
  -->

<!-- Upstream -->
[the uci system]: https://openwrt.org/docs/guide-user/base-system/uci

<!-- Knowledge base -->
[Turris Omnia]: turris%20os.md
