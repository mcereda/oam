# Docker

1. [TL;DR](#tldr)
1. [Gotchas](#gotchas)
1. [Daemon configuration](#daemon-configuration)
   1. [Credentials](#credentials)
1. [Images configuration](#images-configuration)
1. [Building images](#building-images)
   1. [Exclude files from the build context](#exclude-files-from-the-build-context)
   1. [Only include what the final image needs](#only-include-what-the-final-image-needs)
1. [Containers configuration](#containers-configuration)
1. [Health checks](#health-checks)
1. [Advanced build with `buildx`](#advanced-build-with-buildx)
   1. [Create builders](#create-builders)
   1. [Build for specific platforms](#build-for-specific-platforms)
1. [Compose](#compose)
1. [Best practices](#best-practices)
1. [Troubleshooting](#troubleshooting)
    1. [Use environment variables in the ENTRYPOINT](#use-environment-variables-in-the-entrypoint)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

<details>
  <summary>Setup</summary>

| OS       | Setup type       | Engine configuration file                                                  | Settings                                                          | Data directory          |
| -------- | ---------------- | -------------------------------------------------------------------------- | ----------------------------------------------------------------- | ----------------------- |
| Linux    | Engine, regular  | `/etc/docker/daemon.json`                                                  |                                                                   | `/var/lib/docker`       |
| Linux    | Engine, rootless | `${XDG_CONFIG_HOME}/docker/daemon.json`<br/>`~/.config/docker/daemon.json` |                                                                   |                         |
| Linux    | Docker Desktop   | `${HOME}/.docker/daemon.json`                                              | `${HOME}/.docker/desktop/settings.json`                           |                         |
| Mac OS X | Docker Desktop   | `${HOME}/.docker/daemon.json`                                              | `${HOME}/Library/Group Containers/group.com.docker/settings.json` |                         |
| Windows  | Docker Desktop   | `C:\ProgramData\docker\config\daemon.json`                                 | `C:\Users\UserName\AppData\Roaming\Docker\settings.json`          | `C:\ProgramData\docker` |

```sh
# Install.
brew install --cask 'docker'
sudo zypper install 'docker'

# Configure.
vim '/etc/docker/daemon.json'
jq -i '."log-level"="info"' '/etc/docker/daemon.json'
jq -i '.dns=["8.8.8.8", "1.1.1.1"]' "${HOME}/.docker/daemon.json"
```

</details>
<details>
  <summary>Usage</summary>

```sh
# Show locally available images.
docker images -a

# Search for images.
docker search 'boinc'

# Login to registries.
docker login
docker login -u 'username' -p 'password'
aws ecr get-login-password \
| docker login --username 'AWS' --password-stdin '012345678901.dkr.ecr.eu-east-2.amazonaws.com'

# Pull images.
docker pull 'alpine:3.14'
docker pull 'boinc/client:latest'
docker pull 'moby/buildkit@sha256:00d2…'
docker pull 'pulumi/pulumi-nodejs:3.112.0@sha256:37a0…'
docker pull 'quay.io/strimzi/kafka:latest-kafka-3.6.1'
docker pull '012345678901.dkr.ecr.eu-west-1.amazonaws.com/example-com/syncthing:1.27.8'

# Remove images.
docker rmi 'node'
docker rmi 'alpine:3.14'
docker rmi 'f91a431c5276'

# Create containers.
docker create -h 'alpine-test-host' --name 'alpine-test-container' 'alpine:3.19'
docker create … 'quay.io/strimzi/kafka:latest-kafka-3.6.1'

# Start containers.
docker start 'alpine-test-container'
docker start 'bdbe3f45'

# Create and start containers.
docker run 'hello-world'
docker run -ti --rm --platform 'linux/amd64' 'alpine:3.19' cat '/etc/apk/repositories'
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
docker logs -f 'alpine-test'
docker logs --since '1m' 'dblab_server' --details
docker logs --since '2024-05-01' -n '100' 'mariadb'
docker logs --since '2024-08-01T23:11:35' --until '2024-08-05T20:43:35' 'gitlab'

# List processes running inside containers.
docker top 'alpine-test'

# Show information on containers.
docker inspect 'alpine-test'
docker inspect --format='{{index .RepoDigests 0}}' 'pulumi/pulumi-nodejs:3.112.0'

# Build a docker image.
docker build -t 'private/alpine:3.14' .

# Tag images.
docker tag 'alpine:3.14' 'private/alpine:3.14'
docker tag 'f91a431c5276' 'pulumi/pulumi-nodejs:3.112.0'

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
docker builder prune -a
docker buildx prune -a

# List networks.
docker network ls

# Inspect networks.
docker network inspect 'monitoring_default'

# Create volumes.
docker volume create 'volume-name'

# List volumes.
docker volume list

# Inspect volumes.
docker volume inspect 'volume-name'

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
docker buildx build … -t 'image:tag' --load --platform 'linux/amd64' '.'
docker buildx build … --push \
  --cache-to 'mode=max,image-manifest=true,oci-mediatypes=true,type=registry,ref=012345678901.dkr.ecr.eu-west-2.amazonaws.com/buildkit-test:cache \
  --cache-from type=registry,ref=012345678901.dkr.ecr.eu-west-2.amazonaws.com/buildkit-test:cache \
  --platform 'linux/amd64,linux/arm64,linux/arm/v7' '.'

# Clean up the build cache.
docker buildx prune
docker buildx prune -a

# Remove builders.
docker buildx rm 'builder_name'

# Pull images used in compositions.
docker compose pull

# Start compositions.
docker compose up
docker compose up -d

# Execute commands in compositions' containers
docker compose exec 'service-name' 'ls' '-Al'

# Get logs.
docker compose logs
docker compose logs -f --index='3' 'service-name'

# End compositions.
docker compose down
```

</details>
<details style="margin: 0 0 1em 0">
  <summary>Real world use cases</summary>

```sh
# Get the SHAsum of images.
docker inspect --format='{{index .RepoDigests 0}}' 'node:18-buster'

# Act upon files in volumes.
sudo ls "$(docker volume inspect --format '{{.Mountpoint}}' 'baikal_config')"
sudo vim "$(docker volume inspect --format '{{.Mountpoint}}' 'gitea_config')/app.ini"

# Send images to other nodes with Docker.
docker save 'local/image:latest' | ssh -C 'user@remote.host' docker load
```

</details>

The Docker engine leverages specific Linux capabilities.

On Windows and Mac OS X the engine runs in Linux VMs.<br/>
Docker's `host` network mode will use the VM's network, and **not** the host's one. Using that mode on those OSes will
result in the containers being **silently unable** to receive traffic from outside the host.<br/>
To solve this, use a different network mode and **explicitly publish** the ports used.

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

- When referring to a container or image using their ID, you just need to use as many characters you need to uniquely
  specify a single one of them:

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

- Docker's host networking feature is not supported on Mac, even though the `docker run` command doesn't complain about
  it.<br/>
  This is due to the fact that the Docker daemon on Mac is running in a virtual machine, and not natively; hence, ports
  are exposed on the VM and not of the host running it.<br/>
  One way around it is port forwarding to localhost (the `-p` or `-P` options).

## Daemon configuration

The docker daemon is configured using the `/etc/docker/daemon.json` file:

```json
{
    "default-runtime": "runc",
    "dns": ["8.8.8.8", "1.1.1.1"]
}
```

### Credentials

Configured in the `${HOME}/.docker/config.json` file of the user executing docker commands:

```json
{
  "credsStore": "ecr-login",
  "auths": {
    "https://index.docker.io/v1/": {
      "auth": "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ101234"
    }
  }
}
```

The `ecr-login` credentials store requires the [`amazon-ecr-credential-helper`][amazon-ecr-credential-helper] to be
present on the system.

```sh
brew install 'docker-credential-helper-ecr'
dnf install 'amazon-ecr-credential-helper'
```

## Images configuration

One should follow the [OpenContainers Image Spec].

## Building images

Also see [Advanced build with `buildx`](#advanced-build-with-buildx).

### Exclude files from the build context

Leverage a `.dockerignore` file.

Refer [How to Use a .dockerignore File: A Comprehensive Guide with Examples]

### Only include what the final image needs

Leverage [Multi-stage builds].

## Containers configuration

Docker mounts specific system files in all containers to forward its settings:

```sh
6a95fabde222$ mount
/dev/disk/by-uuid/1bb…eb5 on /etc/resolv.conf type btrfs (rw,…)
/dev/disk/by-uuid/1bb…eb5 on /etc/hostname type btrfs (rw,…)
/dev/disk/by-uuid/1bb…eb5 on /etc/hosts type btrfs (rw,…)
```

Those files come from the volume the docker container is using for its root, and are modified on the container's startup
with the information from the CLI, the daemon itself and, when missing, the host.

## Health checks

The following have the same effect:

<details><summary>Command line</summary>

```sh
docker run … \
  --health-cmd 'curl --fail --insecure --silent --show-error http://localhost/ || exit 1' \
  --health-interval '5m' \
  --health-timeout '3s' \
  --health-retries '4' \
  --health-start-period '10s'
```

</details>
<details><summary>Dockerfile</summary>

```Dockerfile
HEALTHCHECK --interval=5m --timeout=3s --start-period=10s --retries=4 \
  CMD curl --fail --insecure --silent --show-error http://localhost/ || exit 1
```

</details>
<details><summary>Docker-compose file</summary>

```yaml
version: '3.6'
services:
  web-server:
    healthcheck:
      test: curl --fail --insecure --silent --show-error http://localhost/ || exit 1
      interval: 5m
      timeout: 3s
      retries: 4
      start_period: 10s
    …
```

</details><br/>

The command's exit status indicates the health status of the container. The possible values are:

- `0`: success - the container is healthy and ready for use
- `1`: unhealthy - the container isn't working correctly
- `2`: reserved - don't use this exit code

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

## Compose

Refer [Docker compose].

<details>
  <summary>Setup</summary>

  <details style="padding-left: 1em;">
    <summary>Via shell</summary>

```sh
mkdir -p '/usr/local/lib/docker/cli-plugins' \
&& curl 'https://github.com/docker/compose/releases/latest/download/docker-compose-linux-aarch64' \
    -o '/usr/local/lib/docker/cli-plugins/docker-compose' \
&& chmod 'ug=rwx,o=rx' '/usr/local/lib/docker/cli-plugins/docker-compose'
```

  </details>

  <details style="padding-left: 1em;">
    <summary>Via Ansible</summary>

```yml
- name: Create Docker's CLI plugins directory
  become: true
  ansible.builtin.file:
    dest: /usr/local/lib/docker/cli-plugins
    state: directory
    owner: root
    group: root
    mode: u=rwx,g=rx,o=rx
- name: Get Docker compose from its official binaries
  become: true
  ansible.builtin.get_url:
    url: https://github.com/docker/compose/releases/latest/download/docker-compose-{{ ansible_system }}-{{ ansible_architecture }}
    dest: /usr/local/lib/docker/cli-plugins/docker-compose
    owner: root
    group: root
    mode: u=rwx,g=rx,o=rx
```

  </details>

</details>

## Best practices

- Use multi-stage `Dockerfile`s when possible to reduce the final image's size.
- Use a `.dockerignore` file to exclude from the build context all files that are not needed for it.

## Troubleshooting

### Use environment variables in the ENTRYPOINT

Refer [Exec form ENTRYPOINT example].

<details>
  <summary>Root cause</summary>

The ENTRYPOINT's _exec_ form does **not** invoke a command shell. This means that environment substitution
does not happen like it would in shell environments.<br/>
I.E., `ENTRYPOINT [ "echo", "$HOME" ]` will **not** do variable substitution on `$HOME`, while `ENTRYPOINT echo $HOME`
will.

</details>

<details>
  <summary>Solution</summary>

Use the ENTRYPOINT's _shell_ form instead of its _exec_ form:

```diff
-ENTRYPOINT [ "echo", "$HOME" ]
+ENTRYPOINT echo $HOME
```

Alternatively, keep the exec form but force invoking a shell in it:

```diff
-ENTRYPOINT [ "echo", "$HOME" ]
+ENTRYPOINT [ "sh", "-c", "echo", "$HOME" ]
```

</details>

## Further readings

- [GitHub]
- [Podman]
- [Dive]
- [Testcontainers]
- [Containerd]
- [Kaniko]
- [`amazon-ecr-credential-helper`][amazon-ecr-credential-helper]
- [Announcing remote cache support in Amazon ECR for BuildKit clients]
- [Docker compose]

### Sources

- [Arch Linux Wiki]
- [Configuring DNS]
- [Cheatsheet]
- [Getting around Docker's host network limitation on Mac]
- [Dockerfile reference]
- [Building multi-arch images for ARM and x86 with Docker Desktop]
- [OpenContainers Image Spec]
- [Docker ARG, ENV and .env - a Complete Guide]
- [Configuring HealthCheck in docker-compose]
- [Docker Buildx Bake + Gitlab CI Matrix]
- [How to list the content of a named volume in docker 1.9+?]
- [Difference between Expose and Ports in Docker Compose]
- [Unable to reach services behind VPN from docker container]
- [Improve docker volume performance on MacOS with a RAM disk]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[containerd]: containerd.md
[dive]: dive.md
[kaniko]: kaniko.md
[podman]: podman.md
[testcontainers]: testcontainers.md

<!-- Upstream -->
[building multi-arch images for arm and x86 with docker desktop]: https://www.docker.com/blog/multi-arch-images/
[docker compose]: https://github.com/docker/compose
[dockerfile reference]: https://docs.docker.com/reference/dockerfile/
[Exec form ENTRYPOINT example]: https://docs.docker.com/reference/dockerfile/#exec-form-entrypoint-example
[github]: https://github.com/docker
[Multi-stage builds]: https://docs.docker.com/build/building/multi-stage/

<!-- Others -->
[amazon-ecr-credential-helper]: https://github.com/awslabs/amazon-ecr-credential-helper
[announcing remote cache support in amazon ecr for buildkit clients]: https://aws.amazon.com/blogs/containers/announcing-remote-cache-support-in-amazon-ecr-for-buildkit-clients/
[arch linux wiki]: https://wiki.archlinux.org/index.php/Docker
[cheatsheet]: https://collabnix.com/docker-cheatsheet/
[configuring dns]: https://dockerlabs.collabnix.com/intermediate/networking/Configuring_DNS.html
[configuring healthcheck in docker-compose]: https://medium.com/@saklani1408/configuring-healthcheck-in-docker-compose-3fa6439ee280
[difference between expose and ports in docker compose]: https://www.baeldung.com/ops/docker-compose-expose-vs-ports
[docker arg, env and .env - a complete guide]: https://vsupalov.com/docker-arg-env-variable-guide/
[docker buildx bake + gitlab ci matrix]: https://teymorian.medium.com/docker-buildx-bake-gitlab-ci-matrix-77edb6b9863f
[getting around docker's host network limitation on mac]: https://medium.com/@lailadahi/getting-around-dockers-host-network-limitation-on-mac-9e4e6bfee44b
[how to list the content of a named volume in docker 1.9+?]: https://stackoverflow.com/questions/34803466/how-to-list-the-content-of-a-named-volume-in-docker-1-9
[How to Use a .dockerignore File: A Comprehensive Guide with Examples]: https://hn.mrugesh.dev/how-to-use-a-dockerignore-file-a-comprehensive-guide-with-examples
[improve docker volume performance on macos with a ram disk]: https://thoughts.theden.sh/posts/docker-ramdisk-macos-benchmark/
[opencontainers image spec]: https://specs.opencontainers.org/image-spec/
[unable to reach services behind vpn from docker container]: https://github.com/docker/for-mac/issues/5322
