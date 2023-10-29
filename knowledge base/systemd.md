# Systemd

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [User services](#user-services)
1. [Keep past boots record (persistent logging)](#keep-past-boots-record-persistent-logging)
1. [Resolved](#resolved)
   1. [Disable systemd-resolved](#disable-systemd-resolved)
   1. [Ignore the DNS servers list given by the DHCP server](#ignore-the-dns-servers-list-given-by-the-dhcp-server)
   1. [Manually set DNS servers](#manually-set-dns-servers)
1. [Sources](#sources)

## TL;DR

```sh
# List all available units.
systemctl list-unit-files

# List failed units only.
systemctl list-units --state='failed'

# Start services.
sudo systemctl start 'adb.service'
systemctl --user start 'keybase.service'

# Restart services.
sudo systemctl restart 'bluetooth.service'
systemctl --user restart 'davmail.service'

# Stop services.
sudo systemctl stop 'cups.service'
systemctl --user stop 'davmail.service'

# Enable services on boot.
sudo systemctl enable 'sshd.service'
sudo systemctl enable --now 'docker.service'
systemctl --user enable --now 'davmail.service'

# Disable services from boot.
sudo systemctl disable 'clamav-freshclam.service'
sudo systemctl disable --now 'gdm.service'
systemctl --user disable --now 'davmail.service'

# Check a service is currently active.
systemctl is-active 'wpa_supplicant.service'

# Reboot the system.
systemctl reboot

# Suspend the system.
# Saves the state to RAM only.
systemctl suspend

# Hibernate the system.
# Saves the state to disk only.
systemctl hibernate

# Suspend the system in hybrid mode.
# Saves the state to *both* RAM *and* disk.
systemctl hybrid-sleep

# Suspend the system, then hibernate after some time.
# Saves the state to RAM initially, and if not interrupted within the specified
# delay then wake up using an RTC alarm and hibernate.
# Specify such delay in HibernateDelaySec in systemd-sleep.conf(5).
systemctl suspend-then-hibernate

# Show log entries.
journalctl
journalctl -f
journalctl -n '20'
journalctl -o 'json-pretty'
journalctl --no-pager
journalctl --utc

# Show what boots the system has logs about.
journalctl --list-boots

# Display logs from specific boots only.
# Persistent logging needs to be enabled.
journalctl -b
journalctl -b -3

# Display logs in a specific time window
journalctl --since 'yesterday'
journalctl --since "2015-01-10 17:15:00"
journalctl --since '09:00' --until "1 hour ago"
journalctl --since "2015-01-10" --until "2015-01-11 03:00"

# Filter logs by unit.
journalctl -u 'nginx.service'
journalctl -u 'nginx.service' -u 'php-fpm.service' --since 'today'

# Filter logs by process, user id or group id.
journalctl _PID='8088'
journalctl _UID='33' --since 'today'
journalctl -F '_GID'

# Filter logs by path.
journalctl '/usr/bin/bash'

# Filter logs by identifier (like a tag).
journalctl -t 'CROND'

# Display kernel logs only.
# Works like `dmesg`.
journalctl -k
journalctl -k -b -5

# Filter logs by priority.
journalctl -p err -b

# Truncate the output.
journalctl --no-full

# Print everything.
journalctl -a

# Show current logs disk usage.
journalctl --disk-usage

# Delete old logs.
sudo journalctl --vacuum-size='1G'
sudo journalctl --vacuum-time='1years'

# Show the current time settings.
timedatectl

# List available timezones.
timedatectl list-timezones

# Set timezones.
sudo timedatectl set-timezone 'UTC'
sudo timedatectl set-timezone 'Europe/Dublin'

# Set the time.
sudo timedatectl set-time '15:58:30'
sudo timedatectl set-time '2015-11-20 16:14:50'

# Set the hardware clock to UTC.
timedatectl set-local-rtc 0

# Set the hardware clock to local timezone.
timedatectl set-local-rtc 1

# Set automatic time sync.
sudo timedatectl set-ntp true
sudo timedatectl set-ntp false

# Check the time and timezones state.
timedatectl status

# Show the current hostname settings.
hostnamectl
hostnamectl --pretty status
hostnamectl --static status

# Set hostnames.
hostnamectl set-hostname 'static_hostname' --static
hostnamectl set-hostname 'pretty_hostname' --pretty

# Show the current DNS resolution settings.
resolvectl status
resolvectl status 'eth0'

# Get an address-ip resolution and viceversa.
resolvectl query 'www.0pointer.net'
resolvectl query '85.214.157.71'

# Retrieve PGP keys.
resolvectl openpgp 'zbyszek@fedoraproject.org'

# Restart the DNS resolver.
sudo systemctl restart 'systemd-resolved.service'

# See the status of the DNS resolver.
systemd-resolve --status

# Resolve hostnames or IP addresses.
systemd-resolve 'google.com'
systemd-resolve '8.8.8.8'

# Set interface-specific DNS server address and search domain.
sudo systemd-resolve -i 'wlp2s0' --set-dns '192.168.1.1' --set-domain 'lan'
```

## User services

User's service files should be placed into `~/.config/systemd/user`:

```sh
cat > "${HOME}/.config/systemd/user/davmail.service" <<EOF
[Unit]
Description=Davmail

[Service]
ExecStart=/usr/bin/davmail -notray

[Install]
WantedBy=default.target
EOF
```

and can be acted upon as normal using `systemctl`'s `--user` switch

```sh
systemctl --user enable --now 'davmail.service'
systemctl --user status 'davmail.service'
```

## Keep past boots record (persistent logging)

Edit the journal configuration file and set the following option:

```ini
# file /etc/systemd/journald.conf
[Journal]
Storage=persistent
```

## Resolved

### Disable systemd-resolved

1. disable and stop the systemd-resolved service:

   ```sh
   sudo systemctl disable --now 'systemd-resolved.service'
   ```

1. set NetworkManager to use the default DNS resolution.

   ```ini
   # file /etc/NetworkManager/NetworkManager.conf
   [main]
   dns=default
   ```

1. delete `/etc/resolv.conf`:

   ```sh
   sudo unlink '/etc/resolv.conf'
   ```

1. restart NetworkManager

   ```sh
   sudo service 'network-manager' restart
   ```

### Ignore the DNS servers list given by the DHCP server

Set the following lines in any network-specific file for which you want to ignore DNS servers from DHCP (like `/etc/systemd/network/eth0.network`), or in the global settings (`/etc/systemd/resolved.conf` or any file in `/etc/systemd/resolved.conf.d/`):

```ini
[DHCP]
UseDNS=false
```

Restarting the `systemd-resolved` service seems to not be enough. Restarting the host changed the settings.

### Manually set DNS servers

Use the handy command:

```sh
sudo systemd-resolve -i 'wlp2s0' --set-dns '192.168.1.1' --set-domain 'lan'
```

or set the following lines in the global settings (`/etc/systemd/resolved.conf` or any file in `/etc/systemd/resolved.conf.d/`), or in any network-specific file you want to set DNS servers for (like `/etc/systemd/network/eth0.network`):

```ini
[Resolve]
DNS=192.168.1.1 # Local router
FallbackDNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001 # Cloudflare
```

Restart the `systemd-resolved` service to apply the new settings.

## Sources

- [How to disable systemd-resolved in Ubuntu]
- [What are the systemctl options to list all failed units?]
- [How To Use Journalctl to View and Manipulate Systemd Logs]
- [How to Set Time, Timezone and Synchronize System Clock Using timedatectl Command]
- [How to Set Hostname Using Hostnamectl Command?]
- [Suspend and hibernate]
- [Changing DNS with systemd-resolved]

<!--
  References
  -->

<!-- Others -->
[changing dns with systemd-resolved]: https://notes.enovision.net/linux/changing-dns-with-resolve
[how to disable systemd-resolved in ubuntu]: https://askubuntu.com/questions/907246/how-to-disable-systemd-resolved-in-ubuntu
[how to set hostname using hostnamectl command?]: https://linuxhint.com/set-hostname-using-hostnamectl-command/
[how to set time, timezone and synchronize system clock using timedatectl command]: https://www.tecmint.com/set-time-timezone-and-synchronize-time-using-timedatectl-command/
[how to use journalctl to view and manipulate systemd logs]: https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs
[suspend and hibernate]: https://wiki.archlinux.org/title/Power_management#Suspend_and_hibernate
[what are the systemctl options to list all failed units?]: https://unix.stackexchange.com/questions/341060/what-are-the-systemctl-options-to-list-all-failed-units/341061#341061
