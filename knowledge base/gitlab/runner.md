# Gitlab runner

TODO

1. [TL;DR](#tldr)
1. [Pull images from private AWS ECR registries](#pull-images-from-private-aws-ecr-registries)
1. [Autoscaling](#autoscaling)
   1. [Docker Machine](#docker-machine)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Installation</summary>

```sh
brew install 'gitlab-runner'
dnf install 'gitlab-runner'
docker pull 'gitlab/gitlab-runner'
helm --namespace 'gitlab' upgrade --install --create-namespace --version '0.64.1' --repo 'https://charts.gitlab.io' \
  'gitlab-runner' -f 'values.gitlab-runner.yml' 'gitlab/gitlab-runner'
```

</details>

<details>
  <summary>Usage</summary>

```sh
docker run --rm --name 'runner' 'gitlab/gitlab-runner:alpine-v13.6.0' --version

# `gitlab-runner exec` is deprecated and has been removed in 17.0. ┌П┐(ಠ_ಠ) Gitlab.
# See https://docs.gitlab.com/16.11/runner/commands/#gitlab-runner-exec-deprecated.
gitlab-runner exec docker 'job-name'
gitlab-runner exec docker \
  --env 'AWS_ACCESS_KEY_ID=AKIA…' --env 'AWS_SECRET_ACCESS_KEY=F…s' --env 'AWS_REGION=eu-east-1' \
  --env 'DOCKER_AUTH_CONFIG={ "credsStore": "ecr-login" }' \
  --docker-volumes "$HOME/.aws/credentials:/root/.aws/credentials:ro"
  'job-requiring-ecr-access'
```

</details>

## Pull images from private AWS ECR registries

1. Create an IAM Role in one's AWS account and attach it the
   `arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly` IAM policy.
1. Create and InstanceProfile using the above IAM Role.
1. Create an EC2 Instance.<br/>
   Make it use the above InstanceProfile.
1. Install the Docker Engine and the [Gitlab runner][install gitlab runner] on the EC2 Instance.
1. Install the [Amazon ECR Docker Credential Helper].
1. Configure an AWS Region in `/root/.aws/config`:

   ```ini
   [default]
   region = eu-west-1
   ```

1. Create the `/root/.docker/config.json` file and add the following line to it:

   ```diff
    {
      …
   + "credsStore": "ecr-login"
    }
   ```

1. Configure the runner to use the [`docker`][docker executor] or [`docker+machine`][docker machine] executor.

   ```toml
   [[runners]]
   executor = "docker"   # or "docker+machine"
   ```

1. Configure the runner to use the ECR Credential Helper:

   ```toml
   [[runners]]
     [runners.docker]
     environment = [ 'DOCKER_AUTH_CONFIG={"credsStore":"ecr-login"}' ]
   ```

1. Configure jobs to use images saved in private AWS ECR registries:

   ```yaml
   phpunit:
     stage: testing
     image:
       name: 123456789123.dkr.ecr.eu-west-1.amazonaws.com/php-gitlabrunner:latest
       entrypoint: [""]
     script:
       - php ./vendor/bin/phpunit --coverage-text --colors=never
   ```

Now your GitLab runner should automatically authenticate to one's private ECR registry.

## Autoscaling

### Docker Machine

Runner like any others, just configured to use the `docker+machine` executor.

[Supported cloud providers][docker machine's supported cloud providers].

Pitfalls:

- On AWS, the driver supports only one subnet.<br/>
  See [AWS driver does not support multiple non default subnets] and [Docker Machine's AWS driver's options].

## Further readings

- [Gitlab]
- [Amazon ECR Docker Credential Helper]
- Gitlab's [docker machine] fork
- Gitlab's [gitlab-runner-operator] for OpenShift and Kubernetes

### Sources

- [Install Gitlab runner]
- [Docker executor]
- [Authenticating your GitLab CI runner to an AWS ECR registry using Amazon ECR Docker Credential Helper]
- [Install and register GitLab Runner for autoscaling with Docker Machine]
- [AWS driver does not support multiple non default subnets]
- [GitLab Runner Helm Chart]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[gitlab]: README.md

<!-- Files -->
<!-- Upstream -->
[docker executor]: https://docs.gitlab.com/17.0/runner/executors/docker.html
[docker machine]: https://gitlab.com/gitlab-org/ci-cd/docker-machine
[docker machine's aws driver's options]: https://gitlab.com/gitlab-org/ci-cd/docker-machine/-/blob/main/docs/drivers/aws.md#options
[docker machine's supported cloud providers]: https://docs.gitlab.com/runner/configuration/autoscale.html#supported-cloud-providers
[install gitlab runner]: https://docs.gitlab.com/runner/install/
[install and register gitlab runner for autoscaling with docker machine]: https://docs.gitlab.com/17.0/runner/executors/docker_machine.html
[gitlab-runner-operator]: https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator
[gitlab runner helm chart]: https://docs.gitlab.com/runner/install/kubernetes.html

<!-- Others -->
[authenticating your gitlab ci runner to an aws ecr registry using amazon ecr docker credential helper]: https://faun.pub/authenticating-your-gitlab-ci-runner-to-an-aws-ecr-registry-using-amazon-ecr-docker-credential-b4604a9391eb
[aws driver does not support multiple non default subnets]: https://github.com/docker/machine/issues/4700
[amazon ecr docker credential helper]: https://github.com/awslabs/amazon-ecr-credential-helper
