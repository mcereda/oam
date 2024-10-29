# Kaniko

Tool to build container images from a Dockerfile with**out** the need of the Docker engine.

1. [TL;DR](#tldr)
1. [Usage in GitLab pipelines](#usage-in-gitlab-pipelines)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

Kaniko requires to be run from a container using the `gcr.io/kaniko-project/executor` image.

It builds images completely in userspace from within the container by executing the Dockerfile's commands in order and
taking a snapshot of the file system after each command result.<br/>
Should there be any changes to the file system, Kaniko takes a snapshot of the change as a _diff_ layer and updates the
resulting image's metadata.

kaniko supports the following storage solutions for the build contexts:

- GCS Bucket
- S3 Bucket
- Azure Blob Storage
- Local Directory
- Local Tar
- Standard Input
- Git Repository

The executor image has the following built in:

- Amazon ECR credential helper.
- Azure ACR credential helper.

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
docker run … 'gcr.io/kaniko-project/executor' … --cache true --custom-platform 'linux/amd64' --build-arg VERSION='1.2'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Test the Dockerfile from an Ansible execution environment the way a GitLab pipeline would need to execute it.
docker run --rm -ti -v "$PWD:/workspace" --entrypoint '' 'gcr.io/kaniko-project/executor:v1.23.2-debug' \
  /kaniko/executor --context '/workspace/context' --dockerfile '/workspace/context/Dockerfile' --no-push
```

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

- [Main repository]

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
[introducing kaniko: build container images in kubernetes and google container builder without privileges]: https://cloud.google.com/blog/products/containers-kubernetes/introducing-kaniko-build-container-images-in-kubernetes-and-google-container-builder-even-without-root-access
[main repository]: https://github.com/GoogleContainerTools/kaniko

<!-- Others -->
[an introduction to kaniko]: https://www.baeldung.com/ops/kaniko
[use kaniko to build docker images]: https://docs.gitlab.com/ee/ci/docker/using_kaniko.html
[kaniko: kubernetes native daemonless docker image builder]: https://8grams.medium.com/kaniko-kubernetes-native-daemonless-docker-image-builder-8eec88979f9e
