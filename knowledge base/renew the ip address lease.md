# Renew the IP address lease

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
- [dhclient]

<!-- internal references -->
[dhclient]: dhclient.md

<!-- external references -->
[force the dhcp client to renew the ip address in linux]: https://www.cyberciti.biz/faq/howto-linux-renew-dhcp-client-ip-address/
