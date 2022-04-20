# Sysctl

Default configuration files locations:

1. `/run/sysctl.d/*.conf`
1. `/etc/sysctl.d/*.conf`
1. `/usr/local/lib/sysctl.d/*.conf`
1. `/usr/lib/sysctl.d/*.conf`
1. `/lib/sysctl.d/*.conf`
1. `/etc/sysctl.conf`

## TL;DR

```shell
# see the value of a single setting
sysctl kernel.ostype

# see the values of all settings
sysctl -a

# change the current value of a setting
sudo sysctl vm.swappiness=10
sudo sysctl -w net.ipv4.ip_forward=1

# reload settings from a single configuration file
sudo sysctl -p
sudo sysctl -p /etc/sysctl.d/99-swappiness.conf

# reload settings from the default configuration files locations
sudo sysctl --system

# persistent configuration
echo 'vm.swappiness=10'  | sudo tee -a /etc/sysctl.conf
echo 'vm.swappiness = 5' | sudo tee -a /etc/sysctl.d/99-swappiness.conf
```

## Further readings

- [How to reload sysctl.conf variables on Linux]

[how to reload sysctl.conf variables on linux]: https://www.cyberciti.biz/faq/reload-sysctl-conf-on-linux-using-sysctl/
