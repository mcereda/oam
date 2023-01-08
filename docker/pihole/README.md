# Pi-hole

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

- [Docker Hub]

[docker hub]: https://hub.docker.com/r/pihole/pihole
[documentation]: https://docs.pi-hole.net/
[github]: https://github.com/pi-hole/docker-pi-hole/
