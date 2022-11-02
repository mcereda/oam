# Docker

## TL;DR

```sh
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
docker stop 'bdbe3f45'

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
```

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

## Sources

- [Arch Linux Wiki]
- [Configuring DNS]
- [Cheatsheet]

[arch linux wiki]: https://wiki.archlinux.org/index.php/Docker
[cheatsheet]: https://collabnix.com/docker-cheatsheet/
[configuring dns]: https://dockerlabs.collabnix.com/intermediate/networking/Configuring_DNS.html
