# Docker

1. [TL;DR](#tldr)
1. [Gotchas](#gotchas)
1. [Daemon configuration](#daemon-configuration)
1. [Containers configuration](#containers-configuration)
1. [Advanced build with `buildx`](#advanced-build-with-buildx)
   1. [Create builders](#create-builders)
   1. [Build for specific platforms](#build-for-specific-platforms)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Install
brew install --cask 'docker'
sudo zypper install 'docker'


# Show locally available images.
docker images -a

# Search for images.
docker search 'boinc'

# Pull images.
docker pull 'alpine:3.14'
docker pull 'boinc/client:latest'

# Login to registries.
docker login
docker login -u 'username' -p 'password'

# Create containers.
docker create -h 'alpine-test' --name 'alpine-test' 'alpine'

# Start containers.
docker start 'alpine-test'
docker start 'bdbe3f45'

# Create and start containers.
docker run 'hello-world'
docker run -ti --rm 'alpine' cat '/etc/apk/repositories'
docker run -d --name 'boinc' --network='host' --pid='host' -v 'boinc:/var/lib/boinc' \
  -e BOINC_GUI_RPC_PASSWORD='123' -e BOINC_CMD_LINE_OPTIONS='--allow_remote_gui_rpc' \
  'boinc/client'

# Gracefully stop containers.
docker stop 'alpine-test'
docker stop -t '0' 'bdbe3f45'

# Kill containers.
docker kill 'alpine-test'

# Restart containers.
docker restart 'alpine-test'
docker restart 'bdbe3f45'

# Show containers' status.
docker ps
docker ps --all

# List containers with specific metadata values.
docker ps -f 'name=pihole' -f 'status=running' -f 'health=healthy' -q

# Execute commands inside *running* containers.
docker exec 'app_web_1' tail 'logs/development.log'
docker exec -ti 'alpine-test' 'sh'

# Show containers' output.
docker log 'alpine-test'

# List processes running inside containers.
docker top 'alpine-test'

# Show information on containers.
docker inspect 'alpine-test'

# Build a docker image.
docker build -t 'private/alpine:3.14' .

# Tag images.
docker tag 'alpine:3.14' 'private/alpine:3.14'

# Push images.
docker push 'private/alpine:3.14'

# Export images to tarballs.
docker save 'alpine:3.14' -o 'alpine.tar'
docker save 'hello-world' > 'hw.tar'

# Load images from tarballs.
docker load -i 'hw.tar'

# Delete containers.
docker rm 'alpine-test'
docker rm -f '87b27'

# Cleanup.
docker logout
docker rmi 'alpine'
docker image prune -a
docker system prune -a


# Display a summary of the vulnerabilities in images.
# If not given any input, it targets the most recently built image.
docker scout qv
docker scout quickview 'debian:unstable-slim'
docker scout quickview 'archive://hw.tar'

# Display vulnerabilities in images.
docker scout cves
docker scout cves 'alpine'
docker scout cves 'archive://alpine.tar'
docker scout cves --format 'sarif' --output 'alpine.sarif.json' 'oci-dir://alpine'
docker scout cves --format 'only-packages' --only-package-type 'golang' --only-vuln-packages 'fs://.'

# Display base image update recommendations.
docker scout recommendations
docker scout recommendations 'golang:1.19.4' --only-refresh
docker scout recommendations 'golang:1.19.4' --only-update


# List builders.
docker buildx ls

# Create builders.
docker buildx create --name 'builder_name'

# Switch between builders.
docker buildx use 'builder_name'
docker buildx create --name 'builder_name' --use

# Modify builders.
docker buildx create --node 'builder_name'

# Build images.
# '--load' currently only works for builds for a single platform.
docker buildx build -t 'image:tag' --load '.'
docker buildx build … --push \
  --platform 'linux/amd64,linux/arm64,linux/arm/v7' '.'

# Remove builders.
docker buildx rm 'builder_name'
```

## Gotchas

- Containers created with no specified name will be assigned one automatically:

  ```sh
  $ docker create 'hello-world'
  8eaaae8c0c720ac220abac763ad4b477d807be4522d58e334337b1b74a14d0bd

  $ docker create --name 'alpine' 'alpine'
  63b1a0a3e557094eba7f18424fd50d49b36cacbc21f1df60b918b375b857f809

  $ docker ps -a
  CONTAINER ID   IMAGE         COMMAND    CREATED          STATUS    PORTS   NAMES
  63b1a0a3e557   alpine        "/bin/sh"  24 seconds ago   Created           alpine
  8eaaae8c0c72   hello-world   "/hello"   21 seconds ago   Created           sleepy_brown
  ```

- When referring to a container or image using their ID, you just need to use as many characters you need to uniquely specify a single one of them:

  ```sh
  $ docker ps -a
  CONTAINER ID   IMAGE         COMMAND    CREATED          STATUS    PORTS   NAMES
  63b1a0a3e557   alpine        "/bin/sh"  34 seconds ago   Created           alpine
  8eaaae8c0c72   hello-world   "/hello"   31 seconds ago   Created           sleepy_brown

  $ docker start 8
  8

  $ docker ps -a
  CONTAINER ID   IMAGE         COMMAND    CREATED          STATUS                      PORTS   NAMES
  63b1a0a3e557   alpine        "/bin/sh"  48 seconds ago   Created                             alpine
  8eaaae8c0c72   hello-world   "/hello"   45 seconds ago   Exited (0) 10 seconds ago           sleepy_brown
  ```

- Docker's host networking feature is not supported on Mac, even though the `docker run` command doesn't complain about it.<br/>
  This is due to the fact that the Docker daemon on Mac is running in a virtual machine, and not natively; hence, ports are exposed on the VM and not of the host running it.<br/>
  One way around it is port forwarding to localhost (the `-p` or `-P` options).

## Daemon configuration

The docker daemon is configured using the `/etc/docker/daemon.json` file:

```json
{
    "default-runtime": "runc",
    "dns": ["8.8.8.8", "1.1.1.1"]
}
```

## Containers configuration

Docker mounts specific system files in all containers to forward its settings:

```sh
6a95fabde222$ mount
…
/dev/disk/by-uuid/1bb…eb5 on /etc/resolv.conf type btrfs (rw,…)
/dev/disk/by-uuid/1bb…eb5 on /etc/hostname type btrfs (rw,…)
/dev/disk/by-uuid/1bb…eb5 on /etc/hosts type btrfs (rw,…)
…
```

Those files come from the volume the docker container is using for its root, and are modified on the container's startup with the information from the CLI, the daemon itself and, when missing, the host.

## Advanced build with `buildx`

### Create builders

```sh
$ docker buildx ls
NAME/NODE DRIVER/ENDPOINT STATUS  BUILDKIT             PLATFORMS
default * docker
  default default         running v0.11.7+d3e6c1360f6e linux/amd64, linux/amd64/v2, linux/amd64/v3, linux/386

$ docker buildx create --name 'multiarch' --use
multiarch

$ docker buildx ls
NAME/NODE    DRIVER/ENDPOINT             STATUS   BUILDKIT             PLATFORMS
multiarch *  docker-container
  multiarch0 unix:///var/run/docker.sock inactive
default      docker
  default    default                     running  v0.11.7+d3e6c1360f6e linux/amd64, linux/amd64/v2, linux/amd64/v3, linux/386
```

### Build for specific platforms

> The `--load` option currently only works for builds for a single platform.<br/>
> See <https://github.com/docker/buildx/issues/59>.

```sh
docker buildx build --platform 'linux/amd64,linux/arm64,linux/arm/v7' -t 'image:tag' '.'
docker load …
```

## Further readings

- [GitHub]
- [Podman]
- [Dive]
- [Testcontainers]

### Sources

- [Arch Linux Wiki]
- [Configuring DNS]
- [Cheatsheet]
- [Getting around Docker's host network limitation on Mac]
- [Building multi-arch images for ARM and x86 with Docker Desktop]

<!--
  References
  -->

<!-- Knowledge base -->
[containerd]: containerd.placeholder
[dive]: dive.placeholder
[podman]: podman.placeholder
[testcontainers]: testcontainers.placeholder

<!-- Upstream -->
[building multi-arch images for arm and x86 with docker desktop]: https://www.docker.com/blog/multi-arch-images/
[github]: https://github.com/docker

<!-- Others -->
[arch linux wiki]: https://wiki.archlinux.org/index.php/Docker
[cheatsheet]: https://collabnix.com/docker-cheatsheet/
[configuring dns]: https://dockerlabs.collabnix.com/intermediate/networking/Configuring_DNS.html
[getting around docker's host network limitation on mac]: https://medium.com/@lailadahi/getting-around-dockers-host-network-limitation-on-mac-9e4e6bfee44b
