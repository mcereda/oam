# Pi-hole

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# One-step automated install.
curl -sSL 'https://install.pi-hole.net' | bash
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Check the status.
pihole status


# Temporarily disable blocking.
pihole disable '5m'


# Follow the query logs in real-time.
pihole tail
pihole -t


# Set or change the Web Interface's password.
pihole -a -p
pihole -a -p 'new-password'


# Update Graviton's DB.
pihole updateGravity
pihole -g

# Check when Graviton's DB has last been updated.
stat /etc/pihole/gravity.db

# Show Chronometer, the console dashboard of real-time stats.
# Live updates.
pihole -c

# Show Chronometer once, then exit.
pihole -c -e


# Empty Pi-hole's query log.
# Effectively truncates '/var/log/pihole/pihole.log'.
pihole flush


# Backup all settings and the configuration in the current directory.
# The resulting archive can be imported using the Settings > Teleport webpage.
pihole admin teleporter
pihole -a -t

# Backup all settings and the configuration to the specified file.
pihole admin teleporter 'path/to/backup/file.tar.gz'
pihole -a -t 'path/to/backup/file.tar.gz'


# Fully restart Pi-hole's subsystems.
pihole restartdns

# Update the lists and flush the cache *without* restarting the DNS server.
pihole restartdns reload

# Update the lists, but do not flush the cache nor restart the DNS server.
pihole restartdns reload-lists


# Reconfigure or Repair the subsystems.
pihole reconfigure
pihole -r


# Check updates.
pihole updatePihole --check-only
pihole -up --check-only

# Update.
pihole updatePihole
pihole -up
```

</details>

## Further readings

- [Website]
- [Github]
- [The pihole command]
- [DNS]
- [Run Pi-hole as a container with Podman on openSUSE]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[DNS]: dns.md

<!-- Upstream -->
[github]: https://github.com/pi-hole/pi-hole
[the pihole command]: https://docs.pi-hole.net/core/pihole-command/
[website]: https://pi-hole.net/

<!-- Others -->
[run pi-hole as a container with podman on opensuse]: https://www.suse.com/c/pihole-podman-opensuse/
