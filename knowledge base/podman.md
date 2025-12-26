# Podman

Daemonless container engine for Linux.<br/>
Intended to be a drop-in replacement for [Docker].

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Install.
apt install 'podman' 'podman-compose'
dnf install 'podman'
pacman -S 'podman'
zypper install 'podman'

# Add container registries to use.
echo 'unqualified-search-registries = ["docker.io"]' > "$HOME/.config/containers/registries.conf"
echo 'unqualified-search-registries = ["docker.io"]' | tee -a '/etc/containers/registries.conf.d/docker.io'

# Set aliases for container registries.
cat <<EOF | tee '/etc/containers/registries.conf.d/shortnames.conf'
[aliases]
  "orclinx" = "container-registry.oracle.com/os/oraclelinux"
EOF
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Get the version.
podman --version

# Get help.
man podman
man 'containers-registries.conf'

# List local images.
podman image list
podman images

# Search for images.
podman search 'fedora'
podman search --format "{{.Name}}\t{{.Stars}}\t{{.Official}}" --limit 3 'alpine'
podman search --list-tags 'registry.access.redhat.com/ubi8' --limit 4

# Pull images.
podman pull 'docker.io/library/postgres'
podman pull 'docker.io/library/python:3.10'
podman-compose pull

# List volumes.
podman volume ls
podman volume list

# Get a shell in containers.
podman run --rm --name 'syncthing' --tty --interactive --entrypoint 'sh' 'syncthing/syncthing'
podman-compose run --rm --entrypoint 'sh' 'syncthing'

# Check running containers.
podman ps
podman ps --all

# Manage compositions.
podman-compose up
podman-compose up --detach
podman-compose ps
podman-compose down

# Execute commands in containers.
podman-compose exec 'syncthing' whoami

# Clean up.
podman system prune
podman system prune --all
```

</details>

## Further readings

- [Website]
- [Documentation]
- [Docker]
- [Containerd]
- [Kaniko]
- [Volumes and rootless Podman]

### Sources

- [Pull Official Images From Docker Hub Using Podman]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[containerd]: containerd.md
[docker]: docker.md
[kaniko]: kaniko.md

<!-- Upstream -->
[Documentation]: https://docs.podman.io/en/stable/
[Website]: https://podman.io/

<!-- Others -->
[Pull Official Images From Docker Hub Using Podman]: https://www.baeldung.com/ops/podman-pull-image-docker-hub
[Volumes and rootless Podman]: https://blog.christophersmart.com/2021/01/31/volumes-and-rootless-podman/
