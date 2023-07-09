# Pi-hole

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

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

- [Website]
- [Github]
- [`pihole`][pihole] the command
- [Run Pi-hole as a container with Podman on openSUSE]

<!--
  References
  -->

<!-- Upstream -->
[github]: https://github.com/pi-hole/pi-hole
[website]: https://pi-hole.net/

<!-- In-article sections -->
[pihole]: pihole.md

<!-- Others -->
[run pi-hole as a container with podman on opensuse]: https://www.suse.com/c/pihole-podman-opensuse/
