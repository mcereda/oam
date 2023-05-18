# FreeBSD

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Utilities worth noting](#utilities-worth-noting)
1. [The `rc.conf` files](#the-rcconf-files)
1. [Package management](#package-management)
   1. [Manage binary packages with `pkg`](#manage-binary-packages-with-pkg)
   1. [Manage ports from the Ports collection](#manage-ports-from-the-ports-collection)
1. [Enable time sync for the NTP server](#enable-time-sync-for-the-ntp-server)
1. [Graphical UI](#graphical-ui)
   1. [KDE](#kde)
1. [VirtualBox Guest Additions](#virtualbox-guest-additions)
1. [Linux binary compatibility](#linux-binary-compatibility)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Read manual pages.
man 5 'rc.conf'

# Search for keywords in the manual page descriptions.
man -k 'mail'

# Edit files.
edit 'path/to/file'

# Become 'root' from user sessions.
# The user must know root's password *and* be member of the 'wheel' group.
# Use '-' at the end to also load root's environment.
su
su -

# Add new members to groups.
pw groupmod 'group_name' -m 'username'
pw groupmod 'group_name' -m 'username_1','username_N'

# Replace all members in groups.
pw groupmod 'group_name' -M 'username'
pw groupmod 'group_name' -M 'username_1','username_N'

# Change users' default shell.
chpass -s 'path/to/shell' 'username'
chpass -s "$(grep 'bin/zsh' '/etc/shells')" 'username'

# Start services at boot.
sysrc ntpd_enable="YES"
sysrc vboxguest_enable="YES"

# Get the current system's version.
freebsd-version

# Upgrade the system.
# Maintains the current version.
freebsd-update fetch && \
freebsd-update install

# Upgrade the system to a newer version.
freebsd-update upgrade -r '13.2-RELEASE' && \
freebsd-update install

# Initialize the package managers.
pkg bootstrap
portsnap auto

# Update the package cache.
pkg update

# Search for packages.
pkg search 'bash'

# Install packages.
pkg install 'vim'
pkg install -y 'zsh' 'zsh-autosuggestions'

# Upgrade packages.
pkg upgrade
pkg install -y 'zsh' 'zsh-autosuggestions'

# Check for known vulnerabilities in *installed* applications.
pkg audit -F
pkg audit -Fr 'sqlite'

# *Gently* reboot the system.
shutdown -r now
shutdown -r +30 "System will reboot"

# *Gently* shutdown the system.
# `poweroff` is equivalent to `shutdown -p now`.
shutdown -p +5
poweroff
```

## Utilities worth noting

- `bsdinstall`
- `bsdconfig`

## The `rc.conf` files

The `rc.conf` files contain information about the local host name, configuration details for any network interfaces and which services should be started up at system boot.<br/>
Options are set with `name=value` assignments using the `sh(1)` syntax, and the files are included by the various generic startup scripts in `/etc` which than make decision about their internal actions according to their contents.

The `sysrc(8)` command provides a scripting interface to programmatically modify system configuration files.

The `/etc/defaults/rc.conf` file specifies the **default** settings for all the available options. At its very end, it sources, in order:

- the `/etc/rc.conf` file, to allow system administrators to override such default values for the local system, and
- the `/etc/defaults/vendor.conf` file, to allow vendors to override system defaults.

In the very same way, the `/etc/rc.conf.local` file is used to override settings in `/etc/rc.conf` for historical reasons.

In addition to `/etc/rc.conf.local`, one can also place smaller configuration files for each `rc(8)` script in the `/etc/rc.conf.d` or `⟨dir⟩/rc.conf.d` directories specified in `local_startup`, all of which will then be included by the `load_rc_config` function.

For jail configurations, one could use the `/etc/rc.conf.d/jail` file to store configuration options specific to jails only.<br/>
If `local_startup` contains `/usr/local/etc/rc.d` and `/opt/conf`, `/usr/local/rc.conf.d/jail` and `/opt/conf/rc.conf.d/jail` will be loaded too. If `⟨dir⟩/rc.conf.d/⟨name⟩` is a directory, all the files in it will be loaded too.

See the contents of `man 5 rc.conf` for more information.

## Package management

Requires:

- [`pkg`][manage binary packages with pkg] if one wants to deal with binary packages;
- the [Ports collection][manage ports from the ports collection] if one wants to compile and install source code in an automated way.

See [Installing applications] for more information.

### Manage binary packages with `pkg`

```sh
# Bootstrap `pkg`.
# Need to be run as 'root'.
pkg bootstrap

# Update the package cache.
pkg update

# Get help on the command.
pkg help
pkg help 'search'

# Search for packages.
pkg search 'bash'

# Install packages.
pkg install 'vim'
pkg install -y 'zsh' 'zsh-autosuggestions'
```

### Manage ports from the Ports collection

TODO

## Enable time sync for the NTP server

```sh
sysrc ntpd_enable="YES"
sysrc ntpd_sync_on_start="YES"
```

## Graphical UI

### KDE

> Not working (= need to study how to make it work) with Wayland at the time of writing.

```sh
pw groupmod 'video' -m 'user'
pkg install 'xorg' 'sddm' 'plasma5-plasma' 'plasma5-sddm-kcm' 'konsole' 'dolphin-plugins'
sysctl net.local.stream.recvspace=65536 net.local.stream.sendspace=65536
sysrc dbus_enable="YES" sddm_enable="YES"
service 'dbus' start
service 'sddm' start
```

## VirtualBox Guest Additions

1. Install the additions.<br/>
   Use the `-nox11` package for console-only guests.

   ```sh
   pkg update
   pkg install -y 'virtualbox-ose-additions'
   ```

1. Enable the services at boot:

   ```sh
   sysrc vboxguest_enable="YES" vboxservice_enable="YES"
   ```

1. If `ntp` or `ntpdate` are used, disable the additions' time sync:

   ```sh
   sysrc vboxservice_flags="--disable-timesync"
   ```

1. If you plan to use Xorg, also install `xf86-video-vmware`:

   ```sh
   pkg install -y 'xf86-video-vmware'
   ```

## Linux binary compatibility

Already present on the host but disabled by default.

```sh
sysrc linux_enable="YES"
service linux start
```

The Linux service loads kernel modules and mounts the file systems Linux applications expect under `/compat/linux`.<br/>
Linux binaries start in the same way native FreeBSD binaries do; they behave almost exactly like native processes and can be traced and debugged as usual.

A Linux userland must be installed to run Linux software that requires more than just an ABI to work (like depending on common libraries).
Some Linux software is already included in the Ports tree, and installing it will automatically setup the required Linux userland.

```sh
# CentOS userland.
# Will place the base system derived from CentOS 7 into '/compat/linux'.
pkg install 'linux_base-c7'

# Use `debootstrap` for Debian or Ubuntu userland.
# See https://docs.freebsd.org/en/books/handbook/linuxemu/#linuxemu-debootstrap.
```

## Further readings

- The [FreeBSD Handbook]
- [`rc.conf`'s man page][rc.conf man page]
- [Installing applications]
- [Using the Ports collection]
- [Linux binary compatibility]

## Sources

All the references in the [further readings] section, plus the following:

- [NTPdate - not updating to current time]
- [Boinc]
- [sbz's FreeBSD commands cheat-sheet]

<!-- project's references -->
[freebsd handbook]: https://docs.freebsd.org/en/books/handbook/
[installing applications]: https://docs.freebsd.org/en/books/handbook/ports/
[linux binary compatibility]: https://docs.freebsd.org/en/books/handbook/linuxemu/
[rc.conf man page]: https://man.freebsd.org/cgi/man.cgi?rc.conf(5)
[using the ports collection]: https://docs.freebsd.org/en/books/handbook/ports/#ports-using
[wayland]: https://docs.freebsd.org/en/books/handbook/wayland/

<!-- internal references -->
[manage binary packages with pkg]: #manage-binary-packages-with-pkg
[manage ports from the ports collection]: #manage-ports-from-the-ports-collection

<!-- external references -->
[boinc]: https://people.freebsd.org/~pav/boinc.html
[ntpdate - not updating to current time]: https://forums.freebsd.org/threads/ntpdate-not-updating-to-current-time.72847/
[sbz's freebsd commands cheat-sheet]: https://github.com/sbz/freebsd-commands
