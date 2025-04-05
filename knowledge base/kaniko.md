# Kaniko

Tool to build container images from a Dockerfile with**out** the need of the Docker engine.

1. [TL;DR](#tldr)
1. [Usage in GitLab pipelines](#usage-in-gitlab-pipelines)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Kaniko **requires** to be run from a container using the `gcr.io/kaniko-project/executor` image.

It builds images completely in userspace from within the container.<br/>
It does so by executing the Dockerfile's commands, in order, in a directory on the current file system. Should a command
make any changes in that directory, Kaniko takes a snapshot of it as a _diff_ layer and updates the resulting image's
metadata.

Kaniko, like Docker, requires a context for the build process.<br/>
It is defined by the `--context` option and supports the following storage solutions:

- GCS Bucket
- S3 Bucket
- Azure Blob Storage
- Local Directory
- Local Tar
- Standard Input
- Git Repository

The executor's image has the following utilities built in:

- Amazon ECR credential helper.
- Azure ACR credential helper.

Enable the cache with the `--cache` option.<br/>
If using the cache, it (either-or):

- Has to be a container registry.
- Has to be pre-populated, as Kaniko is currently **not** able to manage local caches during execution.<br/>
  Leverage the `warmer` utility in Kaniko for this. Refer [Cache and Kaniko].

<details>
  <summary>Setup</summary>

```sh
docker pull 'gcr.io/kaniko-project/executor'
docker pull 'gcr.io/kaniko-project/executor:debug'
docker pull 'gcr.io/kaniko-project/executor:v1.23.2-debug'
```

</details>

<details>
  <summary>Usage</summary>

```sh
docker run --rm -ti -v "$PWD:/workspace" 'gcr.io/kaniko-project/executor' --no-push
docker run --rm --name 'kaniko' -ti -v "$PWD:/workspace" 'gcr.io/kaniko-project/executor' \
  --context '/workspace/context' --dockerfile '/workspace/context/Dockerfile' --no-push
docker run … \
  -e "GOOGLE_APPLICATION_CREDENTIALS=/kaniko/config.json" \
  -v "$PWD/gcp-secret.json:/kaniko/config.json:ro" \
  -v "$HOME/.docker/config.json:/kaniko/.docker/config.json:ro" \
  -v "$HOME/.aws:/root/.aws:ro" \
  'gcr.io/kaniko-project/executor' \
    --context 'dir://context' \
    --destination 'docker-hub-repo/custom-image:1.2.3' \
    --destination '012345678901.dkr.ecr.eu-west-1.amazonaws.com/aws-repo:1.2.3' \
    --destination 'gcr.io/gcp-project-id/custom-image:1.2.3' \
    --destination 'mycr.azurecr.io/azure-repository:1.2.3'
docker run … -v "$PWD/config.json:/kaniko/.docker/config.json:ro" 'gcr.io/kaniko-project/executor:latest'
docker run … 'gcr.io/kaniko-project/executor' … --cache --custom-platform 'linux/amd64' --build-arg VERSION='1.2'

# Populate build caches.
docker run -it --rm -v "$PWD/cache:/cache" 'gcr.io/kaniko-project/warmer' \
  --image='maven:3-jdk-11-slim' --image='openjdk:11-jre-slim'
```

</details>

<details>
  <summary>Real world use cases</summary>

  <details style="padding-left: 1rem">
    <summary>Create local images using local cache</summary>

Uses images from the local cache.<br/>
It does **not** _save_ cache images in the local cache directory since Kaniko is currently **not** able to manage such
caches during execution. Refer [Cache and Kaniko].

Creates a root-owned file called `image.tar` in the current directory.<br/>
Run `docker load -i 'image.tar'` to load it into Docker as `image:1.0`.

Image and repository names can only contain the characters `abcdefghijklmnopqrstuvwxyz0123456789_-./`.

```sh
docker run --rm -ti -v "$PWD/cache:/cache" 'gcr.io/kaniko-project/warmer' --image='python:3.10'
docker run --rm -ti -v "$PWD:/workspace" 'gcr.io/kaniko-project/executor:debug' --reproducible \
  --no-push --tar-path '/workspace/image.tar' --destination 'image:1.0' \
  --cache --cache-dir '/workspace/cache' --cache-repo 'oci://cache'
```

  </details>

  <details style="padding-left: 1rem">
    <summary>Test the Dockerfile for an Ansible execution environment the way a GitLab pipeline would need to execute it</summary>

```sh
docker run --rm -ti -v "$PWD:/workspace" 'gcr.io/kaniko-project/executor:debug' /kaniko/executor --no-push
docker run --rm -ti -v "$PWD:/workspace" --entrypoint '' 'gcr.io/kaniko-project/executor:v1.23.2-debug' \
  /kaniko/executor --context '/workspace/someDir' --dockerfile '/workspace/someDir/someDockerfile' --no-push
```

  </details>

</details>

## Usage in GitLab pipelines

```yaml
build-container:
  stage: build
  image:
    name: gcr.io/kaniko-project/executor:debug
    entrypoint: [""]
  script:
    - >-
        /kaniko/executor
        --context "${CI_PROJECT_DIR}"
        --destination "${CI_REGISTRY_IMAGE}:latest"
```

## Further readings

- [Codebase]
- [Cache and Kaniko]

### Sources

- [Use kaniko to build Docker images]
- [An Introduction to Kaniko]
- [Introducing kaniko: Build container images in Kubernetes and Google Container Builder without privileges]
- [Kaniko: Kubernetes native daemonless Docker image builder]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
[codebase]: https://github.com/GoogleContainerTools/kaniko
[introducing kaniko: build container images in kubernetes and google container builder without privileges]: https://cloud.google.com/blog/products/containers-kubernetes/introducing-kaniko-build-container-images-in-kubernetes-and-google-container-builder-even-without-root-access

<!-- Others -->
[an introduction to kaniko]: https://www.baeldung.com/ops/kaniko
[cache and kaniko]: https://medium.com/swlh/cache-and-kaniko-2cfb766925af
[kaniko: kubernetes native daemonless docker image builder]: https://8grams.medium.com/kaniko-kubernetes-native-daemonless-docker-image-builder-8eec88979f9e
[use kaniko to build docker images]: https://docs.gitlab.com/ee/ci/docker/using_kaniko.html
