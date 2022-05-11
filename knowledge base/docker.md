# Docker

## TL;DR

```shell
# Run containers.
docker run hello-world
docker run -ti --rm alpine cat /etc/apk/repositories
docker run -d --name boinc --network=host --pid=host -v "boinc:/var/lib/boinc" \
  -e BOINC_GUI_RPC_PASSWORD="123" -e BOINC_CMD_LINE_OPTIONS="--allow_remote_gui_rpc" \
  boinc/client

# Show containers status.
docker ps --all

# Cleanup.
docker system prune -a
```

## Daemon configuration

The docker daemon is configured using the `/etc/docker/daemon.json` file:

```json
{
    "default-runtime": "runc",
    "dns": ['8.8.8.8', '1.1.1.1']
}
```

## Containers configuration

Docker mounts specific system files in all containers to forward its settings:

```shell
6a95fabde222$ mount
…
/dev/disk/by-uuid/1bb…eb5 on /etc/resolv.conf type btrfs (rw,…)
/dev/disk/by-uuid/1bb…eb5 on /etc/hostname type btrfs (rw,…)
/dev/disk/by-uuid/1bb…eb5 on /etc/hosts type btrfs (rw,…)
…
```

Those files come from the volume the docker container is using for its root, and are modified on the container's startup with the information from the CLI, the daemon itself and, when missing, the host.

## Sources

- [Archlinux Wiki]
- [Configuring DNS]

[archlinux wiki]: https://wiki.archlinux.org/index.php/Docker
[configuring dns]: https://dockerlabs.collabnix.com/intermediate/networking/Configuring_DNS.html
