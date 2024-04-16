# Buildah

Tool that facilitates building OCI container images.

Buildah specializes in building OCI images, with its commands replicating all of those found in a Dockerfile.<br/>
This allows building images:

- With and with**out** Dockerfiles.
- **Not** requiring root privileges.
- With**out** running as a daemon.
- By leveraging the API buildah provides.

The ability of building images without Dockerfiles allows for the integration with other scripting languages into the
build process.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Installation and configuration</summary>

```sh
apt install 'buildah'
dnf install 'buildah'
emerge 'app-containers/buildah'
pacman -S 'buildah'
yum install 'buildah'
zypper install 'buildah'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# List images.
buildah images

# Authenticate to container registries.
aws ecr get-login-password | buildah login -u 'AWS' --password-stdin '012345678901.dkr.ecr.eu-east-2.amazonaws.com'

# Pull images.
buildah pull 'alpine'
buildah pull --quiet --creds 'bob' 'boinc/client:amd'
buildah pull --platform 'linux/amd64' --retry '3' --retry-delay '5s' 'docker-daemon:alpine:3.19'
buildah pull '012345678901.dkr.ecr.eu-east-2.amazonaws.com/library/amazoncorretto:17.0.10-al2023-headless@sha256:ec8d…'

# Create working containers based off of images.
buildah from 'alpine'
buildah from --pull --quiet 'boinc/client:amd'
buildah from --name 'starting-working-container' --arch 'amd64' 'docker-archive:/tmp/alpine.tar'
buildah from '012345678901.dkr.ecr.eu-east-2.amazonaws.com/library/amazoncorretto:17.0.10-al2023-headless@sha256:ec8d…'

# List working containers.
buildah containers

# Start working containers.
buildah run 'wc-fedora' -- dnf -y install 'lighttpd'

# Configure started working containers.
buildah config --annotation "com.example.build.host=$(uname -n)" 'wc-fedora'
buildah config --cmd '/usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf' 'wc-fedora'
buildah config --port '80' 'wc-fedora'

# Create images from working containers.
buildah commit 'starting-working-container' 'alpine-custom'
buildah commit --rm 'working-container-removed-after-commit' 'oci-archive:/tmp/alpine-custom.tar'

# Create images.
buildah build -t 'fedora-http-server'
buildah build --pull -t '012345678901.dkr.ecr.eu-east-2.amazonaws.com/me/my-alpine:0.0.1' 'dockerfile-dir'
buildah build --manifest 'me/my-alpine:0.0.1' --platform 'linux/amd64,linux/arm64/v8'
buildah build … --output 'type=tar,dest=/tmp/alpine.tar'

# Inspect stuff.
buildah inspect 'fedora-http-server'
buildah inspect -t 'image' 'cfde91e4763f'
buildah manifest inspect 'me/my-alpine:0.0.1'

# Push images.
buildah push 'cfde91e4763f' 'docker://registry.example.com/repository:tag'
buildah push --disable-compression 'localhost/test-image' 'docker-daemon:test-image:3.0'
buildah push --creds 'kevin:secretWord' --sign-by '7425…109F' 'docker.io/library/debian' 'oci:/path/to/layout:image:tag'
buildah manifest push

# Remove working containers.
buildah rm 'fedora-http-server'
buildah delete 'starting-working-container' … 'debian-working-container'
buildah rm --all

# Remove images.
buildah rmi 'localhost/test-image'
buildah rmi --all --force
buildah rmi --prune 'cfde91e4763f' … 'boinc/client:amd'

# Remove .
buildah prune
buildah prune --all
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Build containers using commands instead of Dockerfiles.
CONTAINER=$(buildah from 'fedora') \
&& buildah run "$CONTAINER" -- dnf -y install 'lighttpd' \
&& buildah config --annotation "com.example.build.host=$(uname -n)" "$CONTAINER" \
&& buildah config --cmd '/usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf' "$CONTAINER" \
&& buildah config --port '80' "$CONTAINER" \
&& buildah commit "$CONTAINER" 'company/lighttpd:testing'

# Clean everything up.
buildah rm --all \
&& buildah prune --all
```

</details>

## Further readings

- [Website]
- [Github]
- [Kaniko]

### Sources

- [Tutorial: Use Buildah in a rootless container with GitLab Runner Operator on OpenShift]
- [Building container image in AWS CodeBuild with buildah]
- [Building multi-architecture containers with Buildah]
- [Use Buildah to build OCI container images]
- [Containers-transports man page]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[kaniko]: kubernetes/kaniko.placeholder

<!-- Files -->
<!-- Upstream -->
[github]: https://github.com/containers/buildah/
[website]: https://buildah.io/

<!-- Others -->
[building container image in aws codebuild with buildah]: https://dev.to/leonards/building-container-image-in-aws-codebuild-with-buildah-8gk
[building multi-architecture containers with buildah]: https://medium.com/oracledevs/building-multi-architecture-containers-with-buildah-44ed100ec3f3
[containers-transports man page]: https://man.archlinux.org/man/extra/containers-common/containers-transports.5.en
[tutorial: use buildah in a rootless container with gitlab runner operator on openshift]: https://docs.gitlab.com/ee/ci/docker/buildah_rootless_tutorial.html
[use buildah to build oci container images]: https://www.linode.com/docs/guides/using-buildah-oci-images/
