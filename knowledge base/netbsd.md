# NetBSD

1. [TL;DR](#tldr)
1. [The `rc.conf` files](#the-rcconf-files)
1. [Package management](#package-management)
   1. [Upgrade the system](#upgrade-the-system)
   1. [Manage ports from the Ports collection](#manage-ports-from-the-ports-collection)
1. [Enable time sync for the NTP server](#enable-time-sync-for-the-ntp-server)
1. [Graphical UI](#graphical-ui)
1. [VirtualBox Guest Additions](#virtualbox-guest-additions)
1. [Linux binary compatibility](#linux-binary-compatibility)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Read manual pages.
man 'man'
man 5 'rc.conf'

# List all available man pages.
man -w 'time'

# Read all available man pages.
man -a 'time'

# Search for keywords in the manual page descriptions.
man -k 'mail'

# Change the keyboard's layout.
wsconsctl -kw encoding=it

# Edit files.
vi 'path/to/file'

# Become 'root' from user sessions.
# The user must know root's password *and* be member of the 'wheel' group.
# Use '-' at the end to also load root's environment.
su
su -

# Add users.
useradd -m 'username'
useradd -mG 'secondary_group' 'username'

# Add new members to groups.
usermod -G 'group_name' 'username'

# Change users' default shell.
chpass -s 'path/to/shell' 'username'
chpass -s "$(grep 'bin/zsh' '/etc/shells')" 'username'

# (Re)start services.
service ntpd restart
service vboxguest restart

# Start services at boot.
echo ntpd_enable="YES" >> '/etc/rc.conf'
echo vboxguest_enable="YES" >> '/etc/rc.conf'

# Upgrade the system to newer *minor* versions.
sysinst
sysupgrade auto 'https://cdn.netbsd.org/pub/NetBSD/NetBSD-10.0/amd64'

# Upgrade the system to newer *major* versions.
sysinst
sysupgrade fetch 'https://cdn.netbsd.org/pub/NetBSD/NetBSD-10.0/amd64' \
&& sysupgrade kernel \
&& sysupgrade modules \
&& reboot \
&& sysupgrade sets \
&& sysupgrade etcupdate \
&& sysupgrade clean \
&& reboot

# Initialize the package managers.
export PKG_PATH="https://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/$(uname -p)/$(uname -r | cut -d '_' -f '1')/All"

# Install packages the basic way.
pkg_add -v 'git'
pkg_add -v 'pkgin'

# Install packages using `pkgin`.
pkgin install 'firefox'
pkgin in 'sqlite3'

# Refresh the packages database.
pkgin update
pkgin up

# Search for packages.
pkgin search 'fish'
pkgin se 'boinc'

# Upgrade packages.
pkgin upgrade
pkgin ug

# List installed packages.
pkgin list
pkgin ls

# *Gently* reboot the system.
shutdown -r now
shutdown -r +30 "System will reboot"

# *Gently* shutdown the system.
# `poweroff` is equivalent to `shutdown -p now`.
shutdown -p +5
poweroff
```

## The `rc.conf` files

TODO

## Package management

### Upgrade the system

TODO

### Manage ports from the Ports collection

TODO

## Enable time sync for the NTP server

```sh
sysrc ntpd_enable="YES"
sysrc ntpd_sync_on_start="YES"
```

## Graphical UI

TODO

## VirtualBox Guest Additions

TODO

## Linux binary compatibility

TODO

## Further readings

- [Website]

### Sources

- [Documentation]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Upstream -->
[documentation]: https://www.netbsd.org/docs/
[website]: https://www.netbsd.org/

<!-- Others -->
