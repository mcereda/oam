# Opkg

## TL;DR

```shell
# update the list of available packages
opkg update

# list available/installed/upgradable packages
opkg list
opkg list-installed
opkg list-upgradable

# install one or more packages
opkg install zram-swap
opkg install http://downloads.openwrt.org/snapshots/trunk/ar71xx/packages/hiawatha_7.7-2_ar71xx.ipk
opkg install /tmp/hiawatha_7.7-2_ar71xx.ipk

# remove one or more packages
opkg remove youtube-dl

# upgrade all installed packages
opkg upgrade

# upgrade one or more specific packages
opkg upgrade vim yubico-pam

# display informations for a specific package
opkg info python3-dns

# list packages providing a file
opkg search /usr/bin/vim

# list user modified configuration files
opkg list-changed-conffiles

# list dependencies of a package
opkg depends dropbear
```

## Further readings

- [Opkg package manager]

[opkg package manager]: https://openwrt.org/docs/guide-user/additional-software/opkg
