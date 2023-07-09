# Pi-hole

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Run on Raspberry Pi.
apt update && apt install -y docker-compose
cd pi-hole && docker-compose up -d

# Upgrade Graviton's DB.
docker exec -ti pihole pihole -g

# Check when Graviton's DB has been updated.
docker exec pihole stat /etc/pihole/gravity.db
```

## Further readings

- [Github]
- [Documentation]

## Sources

All the references in the [further readings] section, plus the following:

- [Docker Hub]

<!--
  References
  -->

<!-- Upstream -->
[docker hub]: https://hub.docker.com/r/pihole/pihole
[documentation]: https://docs.pi-hole.net/
[github]: https://github.com/pi-hole/docker-pi-hole/

<!-- In-article sections -->
[further readings]: #further-readings
