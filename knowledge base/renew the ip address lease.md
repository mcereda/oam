# Renew the IP address lease

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Renew the lease.
sudo dhclient -v
sudo dhclient eth0

# Release the lease.
sudo dhclient -r eth0
```

## Further readings

- [Force the DHCP client to renew the IP address in Linux]
- [`dhclient`][dhclient]

<!--
  References
  -->

<!-- In-article sections -->
[dhclient]: dhclient.md

<!-- Others -->
[force the dhcp client to renew the ip address in linux]: https://www.cyberciti.biz/faq/howto-linux-renew-dhcp-client-ip-address/
