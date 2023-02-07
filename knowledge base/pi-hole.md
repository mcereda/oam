# Pi-hole

## TL;DR

```sh
# One-step automated install.
curl -sSL 'https://install.pi-hole.net' | bash

# Update Graviton's DB.
pihole -g

# Check when Graviton's DB has been updated.
stat /etc/pihole/gravity.db
```

## Further readings

- Pi-hole's [repository]
- The [pihole] command
- [Run Pi-hole as a container with Podman on openSUSE]

<!-- project's references -->
[repository]: https://github.com/pi-hole/pi-hole

<!-- internal references -->
[pihole]: pihole.md

<!-- external references -->
[run pi-hole as a container with podman on opensuse]: https://www.suse.com/c/pihole-podman-opensuse/
