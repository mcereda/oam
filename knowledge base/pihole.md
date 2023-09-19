# The `pihole` command

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

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
```

## Further readings

- [Pi-hole]
- [The pihole command]

<!--
  References
  -->

<!-- Upstream -->
[the pihole command]: https://docs.pi-hole.net/core/pihole-command/

<!-- In-article sections -->
[pi-hole]: pi-hole.md
