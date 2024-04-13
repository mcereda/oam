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

# Create images from working containers.
buildah commit 'starting-working-container' 'alpine-custom'
buildah commit --rm 'working-container-removed-after-commit' 'oci-archive:/tmp/alpine-custom.tar'

# Create images from Dockerfiles.
# The current directory is used as default context path.
buildah build -t 'fedora-http-server'
buildah build --pull -t '012345678901.dkr.ecr.eu-east-2.amazonaws.com/me/my-alpine:0.0.1' 'dockerfile-dir'

# Push images.
buildah push 'cfde91e4763f' 'docker://registry.example.com/repository:tag'
buildah push --disable-compression 'localhost/test-image' 'docker-daemon:test-image:3.0'
buildah push --creds 'kevin:secretWord' --sign-by '7425…109F' 'docker.io/library/debian' 'oci:/path/to/layout:image:tag'
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
```

</details>

## Further readings

- [Website]
- [Github]
- [Kaniko]

### Sources

- [Tutorial: Use Buildah in a rootless container with GitLab Runner Operator on OpenShift]
- [Building container image in AWS CodeBuild with buildah]
- [Use Buildah to build OCI container images]

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
[tutorial: use buildah in a rootless container with gitlab runner operator on openshift]: https://docs.gitlab.com/ee/ci/docker/buildah_rootless_tutorial.html
[use buildah to build oci container images]: https://www.linode.com/docs/guides/using-buildah-oci-images/
