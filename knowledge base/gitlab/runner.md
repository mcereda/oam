# Gitlab runner

1. [TL;DR](#tldr)
1. [Pull images from private AWS ECR registries](#pull-images-from-private-aws-ecr-registries)
1. [Runners on Kubernetes](#runners-on-kubernetes)
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
  'gitlab-runner' -f 'values.gitlab-runner.yml' 'gitlab-runner'
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

Each runner executor is assigned 1 task at a time.

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

## Runners on Kubernetes

[Store tokens in secrets][store registration tokens or runner tokens in secrets] instead of putting the token in the
chart's values.

Requirements:

- A running and configured Gitlab instance.
- A Kubernetes cluster.

Procedure:

1. \[best practice] Create a dedicated namespace:

   ```sh
   kubectl create namespace 'gitlab'
   ```

1. Create a runner in gitlab:

   1. Go to one's Gitlab instance's `/admin/runners` page.
   1. Click on the _New instance runner_ button.
   1. Keep _Linux_ as runner type.
   1. Click on the _Create runner_ button.
   1. Copy the runner's token.

1. (Re-)Create the runners' Kubernetes secret with the runners' token from the previous step:

   ```sh
   kubectl delete --namespace 'gitlab' secret 'gitlab-runner-token' --ignore-not-found
   kubectl create --namespace 'gitlab' secret generic 'gitlab-runner-token' \
     --from-literal='runner-registration-token=""' --from-literal='runner-token=glrt-…'
   ```

   The secret's name **must** be matched in the helm chart's values file.

1. Install the helm chart:

   ```sh
   helm --namespace 'gitlab' upgrade --install --repo 'https://charts.gitlab.io' \
     --values 'values.yaml' \
     'gitlab-runner' 'gitlab-runner'
   ```

   \[best practice] Be sure to match the runner version with the Gitlab server's:

   ```sh
   helm search repo --versions 'gitlab/gitlab-runner'
   ```

<details style="margin-bottom: 1em;">
  <summary>Example helm chart values</summary>

```yaml
gitlabUrl: https://gitlab.example.com/
unregisterRunners: true
concurrent: 20
checkInterval: 3
rbac:
  create: true
metrics:
  enabled: true
runners:
  config: |
    [[runners]]

      [runners.cache]
        Shared = true

      [runners.kubernetes]
        image = "alpine"
        pull_policy = [
          "if-not-present",
          "always"
        ]
        allowed_pull_policies = [
          "if-not-present",
          "always",
          "never"
        ]

        namespace = "{{.Release.Namespace}}"
  name: "runner-on-k8s"
  secret: gitlab-runner-token
tolerations:
  - key: app
    operator: Equal
    value: gitlab
  - key: component
    operator: Equal
    value: runner
podLabels:
  team: engineering
```

</details>

Gotchas:

- The _build_, _helper_ and multiple _service_ containers will all reside in a single pod.<br/>
  If **the sum** of the resources request by **all** of them is too high, it will **not** be scheduled and the pipeline
  will hang and fail.
- If any pod is killed due to OOM, the pipeline that spawned it will hang until it times out.

Improvements:

- Dedicate specific nodes to runner executors.<br/>
  Taint dedicated nodes and add tolerations and affinities to the runner's configuration.

  <details style="margin-bottom: 1em;">

  ```toml
  [[runners]]
    [runners.kubernetes]

    [runners.kubernetes.node_selector]
      gitlab = "true"
      "kubernetes.io/arch" = "amd64"
      "eks.amazonaws.com/capacityType" = "ON_DEMAND"

      [runners.kubernetes.affinity]
        [runners.kubernetes.affinity.node_affinity]
          [runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution]
            [[runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution.node_selector_terms]]
              [[runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution.node_selector_terms.match_expressions]]
                key = "app"
                operator = "In"
                values = [ "gitlab-runner" ]

      [runners.kubernetes.node_tolerations]
        "app=gitlab-runner" = "NoSchedule"
        "node-role.kubernetes.io/master" = "NoSchedule"
        "custom.toleration=value" = "NoSchedule"
        "empty.value=" = "PreferNoSchedule"
        onlyKey = ""
  ```

  </details>

- Avoid massive resource consumption by defaulting to (very?) strict resource requests and limits.

  <details style="margin-bottom: 1em;">

  ```toml
  [[runners]]
    [runners.kubernetes]
      cpu_request = "0.1"
      cpu_limit = "2"
      memory_request = "1Gi"
      memory_limit = "2Gi"
      ephemeral_storage_limit = "512Mi"

      helper_cpu_limit = "0.5"
      helper_memory_limit = "128Mi"
      helper_ephemeral_storage_limit = "64Mi"

      service_cpu_limit = "1"
      service_memory_limit = "0.5Gi"
  ```

  </details>

- Play nice and make sure to leave some space for the host's other workloads by allowing for resource request and limit
  override only up to a point.

  <details style="margin-bottom: 1em;">

  ```toml
  [[runners]]
    [runners.kubernetes]
      cpu_limit_overwrite_max_allowed = "15"
      cpu_request_overwrite_max_allowed = "15"
      memory_limit_overwrite_max_allowed = "62Gi"
      memory_request_overwrite_max_allowed = "62Gi"
      ephemeral_storage_limit_overwrite_max_allowed = "49Gi"
      ephemeral_storage_request_overwrite_max_allowed = "49Gi"

      helper_cpu_limit_overwrite_max_allowed = "0.9"
      helper_cpu_request_overwrite_max_allowed = "0.9"
      helper_memory_limit_overwrite_max_allowed = "1Gi"
      helper_memory_request_overwrite_max_allowed = "1Gi"
      helper_ephemeral_storage_limit_overwrite_max_allowed = "1Gi"
      helper_ephemeral_storage_request_overwrite_max_allowed = "1Gi"

      service_cpu_limit_overwrite_max_allowed = "3.9"
      service_cpu_request_overwrite_max_allowed = "3.9"
      service_memory_limit_overwrite_max_allowed = "15.5Gi"
      service_memory_request_overwrite_max_allowed = "15.5Gi"
      service_ephemeral_storage_limit_overwrite_max_allowed = "15Gi"
      service_ephemeral_storage_request_overwrite_max_allowed = "15Gi"
  ```

  </details>

## Autoscaling

### Docker Machine

Runner like any others, just configured to use the `docker+machine` executor.

[Supported cloud providers][docker machine's supported cloud providers].

Using this executor opens up specific [configuration settings][docker machine executor autoscale configuration].

Pitfalls:

- On AWS, the driver supports only one subnet (and hence 1 AZ) per runner.<br/>
  See [AWS driver does not support multiple non default subnets] and [Docker Machine's AWS driver's options].

<details>
  <summary>Example configuration</summary>

```toml
# Number of jobs *in total* that can be run concurrently by *all* configured runners
# Does *not* affect the *total* upper limit of VMs created by *all* providers
concurrent = 40

[[runners]]
  name = "static-scaler"

  url = "https://gitlab.example.com"
  token = "abcdefghijklmnopqrst"

  executor = "docker+machine"
  environment = [ "AWS_REGION=eu-west-1" ]

  # Number of jobs that can be run concurrently by the VMs created by *this* runner
  # Defines the *upper limit* of how many VMs can be created by *this* runner, since it is 1 task per VM at a time
  limit = 10

  [runners.machine]
    # Static number of VMs that need to be idle at all times
    IdleCount = 0

    # Remove VMs after 5m in the idle state
    IdleTime = 300

    # Maximum number of VMs that can be added to this runner in parallel
    # Defaults to 0 (no limit)
    MaxGrowthRate = 1

    # Template for the VMs' names
    # Must contain '%s'
    MachineName = "static-ondemand-%s"

    MachineDriver = "amazonec2"
    MachineOptions = [
      # Refer the correct driver at 'https://gitlab.com/gitlab-org/ci-cd/docker-machine/-/tree/main/docs/drivers'
      "amazonec2-region=eu-west-1",
      "amazonec2-vpc-id=vpc-1234abcd",
      "amazonec2-zone=a",                              # driver limitation, only 1 allowed
      "amazonec2-subnet-id=subnet-0123456789abcdef0",  # subnet-id in the specified az
      "amazonec2-use-private-address=true",
      "amazonec2-private-address-only=true",
      "amazonec2-security-group=GitlabRunners",

      "amazonec2-instance-type=m6i.large",
      "amazonec2-root-size=50",
      "amazonec2-iam-instance-profile=GitlabRunnerEc2",
      "amazonec2-tags=Team,Infrastructure,Application,Gitlab Runner,SpotInstance,False",
    ]

[[runners]]
  name = "dynamic-scaler"
  executor = "docker+machine"
  limit = 40  # will still respect the global concurrency value

  [runners.machine]
    # With 'IdleScaleFactor' defined, this becomes the upper limit of VMs that can be idle at all times
    IdleCount = 10

    # *Minimum* number of VMs that need to be idle at all times when 'IdleScaleFactor' is defined
    # Defaults to 1; will be set automatically to 1 if set lower than that
    IdleCountMin = 1

    # Number of VMs that need to be idle at all times, as a factor of the number of machines in use
    # In this case: idle VMs = 1.0 * machines in use, min 1, max 10
    # Must be a floating point number
    # Defaults to 0.0
    IdleScaleFactor = 1.0

    IdleTime = 600

    # Remove VMs after 250 jobs
    # Keeps them fresh
    MaxBuilds = 250

    MachineName = "dynamic-spot-%s"
    MachineDriver = "amazonec2"
    MachineOptions = [
      # Refer the correct driver at 'https://gitlab.com/gitlab-org/ci-cd/docker-machine/-/tree/main/docs/drivers'
      "amazonec2-region=eu-west-1",
      "amazonec2-vpc-id=vpc-1234abcd",
      "amazonec2-zone=b",                              # driver limitation, only 1 allowed
      "amazonec2-subnet-id=subnet-abcdef0123456789a",  # subnet-id in the specified az
      "amazonec2-use-private-address=true",
      "amazonec2-private-address-only=true",
      "amazonec2-security-group=GitlabRunners",

      "amazonec2-instance-type=r7a.large",
      "amazonec2-root-size=25",
      "amazonec2-iam-instance-profile=GitlabRunnerEc2",
      "amazonec2-tags=Team,Infrastructure,Application,Gitlab Runner,SpotInstance,True",

      "amazonec2-request-spot-instance=true",
      "amazonec2-spot-price=0.3",
    ]

    # Pump up the volume of available VMs during working hours
    [[runners.machine.autoscaling]]
      Periods = ["* * 9-17 * * mon-fri *"] # Every work day between 9 and 18 Amsterdam time
      Timezone = "Europe/Amsterdam"

      IdleCount = 20
      IdleCountMin = 5
      IdleTime = 3600

      # In this case: idle VMs = 1.5 * machines in use, min 5, max 20
      IdleScaleFactor = 1.5

    # Reduce even more the number of available VMs during the weekends
    [[runners.machine.autoscaling]]
      Periods = ["* * * * * sat,sun *"]
      IdleCount = 0
      IdleTime = 120
      Timezone = "UTC"
```

</details>

## Further readings

- [Gitlab]
- [Amazon ECR Docker Credential Helper]
- Gitlab's [docker machine] fork
- Gitlab's [gitlab-runner-operator] for OpenShift and Kubernetes
- [Docker Machine Executor autoscale configuration]

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
[docker machine executor autoscale configuration]: https://docs.gitlab.com/runner/configuration/autoscale.html
[docker machine's aws driver's options]: https://gitlab.com/gitlab-org/ci-cd/docker-machine/-/blob/main/docs/drivers/aws.md#options
[docker machine's supported cloud providers]: https://docs.gitlab.com/runner/configuration/autoscale.html#supported-cloud-providers
[docker machine]: https://gitlab.com/gitlab-org/ci-cd/docker-machine
[gitlab runner helm chart]: https://docs.gitlab.com/runner/install/kubernetes.html
[gitlab-runner-operator]: https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator
[install and register gitlab runner for autoscaling with docker machine]: https://docs.gitlab.com/17.0/runner/executors/docker_machine.html
[install gitlab runner]: https://docs.gitlab.com/runner/install/
[store registration tokens or runner tokens in secrets]: https://docs.gitlab.com/runner/install/kubernetes.html#store-registration-tokens-or-runner-tokens-in-secrets

<!-- Others -->
[authenticating your gitlab ci runner to an aws ecr registry using amazon ecr docker credential helper]: https://faun.pub/authenticating-your-gitlab-ci-runner-to-an-aws-ecr-registry-using-amazon-ecr-docker-credential-b4604a9391eb
[aws driver does not support multiple non default subnets]: https://github.com/docker/machine/issues/4700
[amazon ecr docker credential helper]: https://github.com/awslabs/amazon-ecr-credential-helper
