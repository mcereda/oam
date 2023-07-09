# Pihole

## TL;DR

```sh
# Check the status.
pihole status

# Temporarily disable blocking.
pihole disable '5m'

# Follow the logs in real-time.
pihole tail

# Set or change the Web Interface's password.
pihole -a -p
pihole -a -p 'new-password'

# Show Chronometer, the console dashboard of real-time stats.
pihole -c

# Show Chronometer and exit.
pihole -c -e

# Empty Pi-hole's logs.
pihole flush

# Update Graviton's DB.
pihole -g

# Backup all settings and the configuration.
# Without a path, the backup will be created in the current directory.
# The resulting archive can be imported using the Settings > Teleport webpage.
pihole -a -t
pihole -a -t 'path/to/backup/file.tar.gz'
```

## Further readings

- [Pi-hole]
- [The pihole command]

<!-- upstream -->
[the pihole command]: https://docs.pi-hole.net/core/pihole-command/

<!-- internal references -->
[pi-hole]: pi-hole.md

<!-- external references -->
