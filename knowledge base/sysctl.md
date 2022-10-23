# Sysctl

Default configuration files locations:

1. `/run/sysctl.d/*.conf`
1. `/etc/sysctl.d/*.conf`
1. `/usr/local/lib/sysctl.d/*.conf`
1. `/usr/lib/sysctl.d/*.conf`
1. `/lib/sysctl.d/*.conf`
1. `/etc/sysctl.conf`

## TL;DR

```sh
# Show the value of a single setting.
sysctl kernel.ostype
sysctl vm.swappiness

# Show the values of all settings.
sysctl -a

# Change the current value of a setting.
sudo sysctl vm.swappiness=10
sudo sysctl -w net.ipv4.ip_forward=1

# Reload settings from specific configuration files.
sudo sysctl -p
sudo sysctl -p /etc/sysctl.d/99-swappiness.conf

# Reload settings from the default configuration files locations.
sudo sysctl --system

# Set up persistent settings.
echo 'vm.swappiness=10'  | sudo tee -a /etc/sysctl.conf
echo 'vm.swappiness = 5' | sudo tee -a /etc/sysctl.d/99-swappiness.conf
```

## Further readings

- [How to reload sysctl.conf variables on Linux]
- [Documentation for /proc/sys]

<!-- official documentation -->
[documentation for /proc/sys]: https://docs.kernel.org/admin-guide/sysctl/

<!-- forums -->
[how to reload sysctl.conf variables on linux]: https://www.cyberciti.biz/faq/reload-sysctl-conf-on-linux-using-sysctl/
