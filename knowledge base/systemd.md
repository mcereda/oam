# Systemd

## TL;DR

```sh
# List all available units.
systemctl list-unit-files

# List failed units only.
systemctl list-units --state=failed

# Start services.
sudo systemctl start adb.service
systemctl --user start keybase.service

# Restart services.
sudo systemctl restart bluetooth.service

# Stop services.
sudo systemctl stop cups.service

# Enable services on boot.
sudo systemctl enable sshd.service
sudo systemctl enable --now docker.service
systemctl --user enable --now davmail.service

# Disable services from boot.
sudo systemctl disable clamav-freshclam.service
sudo systemctl disable --now gdm.service
systemctl --user disable --now davmail.service

# Show log entries.
journalctl
journalctl -f
journalctl -n 20
journalctl -o json-pretty
journalctl --no-pager
journalctl --utc

# Show what boots the system has logs about.
journalctl --list-boots

# Display logs from specific boots only.
# Persistent logging needs to be enabled.
journalctl -b
journalctl -b -3

# Display logs in a specific time window
journalctl --since yesterday
journalctl --since "2015-01-10 17:15:00"
journalctl --since 09:00 --until "1 hour ago"
journalctl --since "2015-01-10" --until "2015-01-11 03:00"

# Filter logs by unit.
journalctl -u nginx.service
journalctl -u nginx.service -u php-fpm.service --since today

# Filter logs by process, user id or group id.
journalctl _PID=8088
journalctl _UID=33 --since today
journalctl -F _GID

# Filter logs by path.
journalctl /usr/bin/bash

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
sudo journalctl --vacuum-size=1G
sudo journalctl --vacuum-time=1years

# List available timezones.
timedatectl list-timezones

# Set timezones.
sudo timedatectl set-timezone UTC
sudo timedatectl set-timezone Europe/Dublin

# Set the time.
sudo timedatectl set-time 15:58:30
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

# Show the current hostname state.
hostnamectl
hostnamectl --pretty status
hostnamectl --static status

# Set hostnames.
hostnamectl set-hostname staticky --static
hostnamectl set-hostname prettiky --pretty
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
systemctl --user enable --now davmail.service
systemctl --user status davmail.service
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
   sudo systemctl disable --now systemd-resolved.service
   ```

1. set NetworkManager to use the default DNS resolution.

   ```ini
   # file /etc/NetworkManager/NetworkManager.conf
   [main]
   dns=default
   ```

1. delete `/etc/resolv.conf`:

   ```sh
   sudo unlink /etc/resolv.conf
   ```

1. restart NetworkManager

   ```sh
   sudo service network-manager restart
   ```

## Sources

- [How to disable systemd-resolved in Ubuntu]
- [What are the systemctl options to list all failed units?]
- [How To Use Journalctl to View and Manipulate Systemd Logs]
- [How to Set Time, Timezone and Synchronize System Clock Using timedatectl Command]
- [How to Set Hostname Using Hostnamectl Command?]

[how to disable systemd-resolved in ubuntu]: https://askubuntu.com/questions/907246/how-to-disable-systemd-resolved-in-ubuntu
[how to set hostname using hostnamectl command?]: https://linuxhint.com/set-hostname-using-hostnamectl-command/
[how to set time, timezone and synchronize system clock using timedatectl command]: https://www.tecmint.com/set-time-timezone-and-synchronize-time-using-timedatectl-command/
[how to use journalctl to view and manipulate systemd logs]: https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs
[what are the systemctl options to list all failed units?]: https://unix.stackexchange.com/questions/341060/what-are-the-systemctl-options-to-list-all-failed-units/341061#341061
