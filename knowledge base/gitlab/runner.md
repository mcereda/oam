# Gitlab runner

1. [TL;DR](#tldr)
1. [Pull images from private AWS ECR registries](#pull-images-from-private-aws-ecr-registries)
1. [Executors](#executors)
   1. [Docker Autoscaler executor](#docker-autoscaler-executor)
   1. [Docker Machine executor](#docker-machine-executor)
   1. [Instance executor](#instance-executor)
1. [Autoscaling](#autoscaling)
   1. [Docker Machine](#docker-machine)
   1. [GitLab Runner Autoscaler](#gitlab-runner-autoscaler)
   1. [Kubernetes](#kubernetes)
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

<details style="padding-bottom: 1em;">
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

Each runner executor is assigned 1 task at a time by default.

Runners seem to require the main instance to give the full certificate chain upon connection.

The `runners.autoscaler.policy.periods` setting appears to be a full blown cron job, not just a time frame.

<details style="margin-top: -1em; padding: 0 0 1em 1em;">

Given the following policies:

```toml
[[runners]]
  [runners.autoscaler]
    [[runners.autoscaler.policy]]
      periods = [ "* 7-19 * * mon-fri" ]
      …
    [[runners.autoscaler.policy]]
      periods = [ "30 8-18 * * mon-fri" ]
      …
```

It will **not** work as _apply policy 1 between 07:00 and 19:00 but override it with policy 2 between 08:30 and
18:30_.<br/>
Instead, the runner will:

- Apply policy 1 every minute of every hour between 07:00 and 19:00, **and**
- Override policy 1 by applying policy 2 only on the 30th minute of every hour between 08:00 and 18:00.

Meaning it will reapply policy 1 at the 31st minute of every hour in the period defined by policy 2.

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

## Executors

### Docker Autoscaler executor

Refer [Docker Autoscaler executor].

Autoscale-enabled wrap for the `docker` executor. Supports all `docker` executor's options and features.<br/>
Creates instances on-demand to accommodate jobs processed by the runner leveraging it, which acts as manager.<br/>
The runner itself will **not** execute jobs, just delegate them.

Leverages [fleeting] plugins to scale automatically.<br/>
Fleeting is an abstraction for a group of autoscaled instances, and uses plugins supporting cloud providers.

Both the manager and the instances executing jobs require the Docker Engine to be installed.<br/>
The manager will connect to the instances via SSH and execute Docker commands. The user it connects with **must** be
able to execute those commands commands (most likely by being part of the `docker` group on the instances).

Container images are pulled by the manager and sent to the instances it creates.<br/>
The instances do not require container registry access themselves this way.

Add the following settings in the `config.toml` file:

```toml
[[runners]]
  executor = "docker-autoscaler"

  [runners.docker]
    image = "busybox:latest"  # or whatever

  [runners.autoscaler]
    plugin = "aws:latest"  # or 'googlecloud' or 'azure' or whatever

    [runners.autoscaler.plugin_config]
      name = "…"  # see plugin docs

    [[runners.autoscaler.policy]]
      idle_count = 5
      idle_time = "20m0s"
```

<details>
  <summary>Example: AWS, 1 instance per job, 5 idle instances for 20min.</summary>

Give each job a dedicated instance.<br/>
As soon as the job completes, the instance is immediately deleted.

Try to keep 5 whole instances available for future demand.<br/>
Idle instances stay available for at least 20 minutes.

Requirements:

- An EC2 instance with Docker Engine to act as manager.
- A Launch Template referencing an AMI equipped with Docker Engine for the runners to use.

  Alternatively, any AMI that can run Docker Engine can be used as long as an appropriate cloud-init configuration is
  provided in the template's `userData`.

  <details style="margin-top: -1em; padding-bottom: 1em;">

  ```yaml
  packages: [ "docker" ]
  runcmd:
    - systemctl daemon-reload
    - systemctl enable --now docker.service
    - grep docker /etc/group -q && usermod -a -G docker ec2-user
  ```

  </details>

  In this case, and specially if the cloud-init process takes long, instances might be considered ready by the ASG but
  jobs might fail if the Docker Engine is not installed and configured properly before they are assigned to the
  instances.<br/>
  Consider creating a new AMI with everything ready for the LT to use, or set up a lifecycle hook in the ASG to give
  instances time to finish preparations before being considered ready by the ASG.
- An AutoScaling Group with the following setting:

  - Minimum capacity = 0.
  - Desired capacity = 0.

  The runner will take care of scaling up and down.
- An IAM Policy granting the **manager** instance the permissions needed to scale the ASG.<br/>
  Refer the [Recommended IAM Policy](https://gitlab.com/gitlab-org/fleeting/plugins/aws#recommended-iam-policy).

  <details style="margin-top: -1em; padding-bottom: 1em;">

  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "AllowAsgDiscovering",
        "Effect": "Allow",
        "Action": [
          "autoscaling:DescribeAutoScalingGroups",
          "ec2:DescribeInstances"
        ],
        "Resource": "*"
      },
      {
        "Sid": "AllowAsgScaling",
        "Effect": "Allow",
        "Action": [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ],
        "Resource": "arn:aws:autoscaling:eu-west-1:012345678901:autoScalingGroup:01234567-abcd-0123-abcd-0123456789ab:autoScalingGroupName/runners-autoscalingGroup"
      },
      {
        "Sid": "AllowManagingAccessToAsgInstances",
        "Effect": "Allow",
        "Action": "ec2-instance-connect:SendSSHPublicKey",
        "Resource": "arn:aws:ec2:eu-west-1:012345678901:instance/*",
        "Condition": {
          "StringEquals": {
            "ec2:ResourceTag/aws:autoscaling:groupName": "runners-autoscalingGroup"
          }
        }
      }
    ]
  }
  ```

  </details>

- \[if needed] The [amazon ecr docker credential helper] installed on the **manager** instance.
- \[if needed] An IAM Policy granting the **manager** instance the permissions needed to pull images from ECRs.

  <details style="margin-top: -1em; padding-bottom: 1em;">

  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
          Sid: "AllowAuthenticatingWithEcr",
          Effect: "Allow",
          Action: "ecr:GetAuthorizationToken",
          Resource: "*",
      },
      {
          Sid: "AllowPullingImagesFromEcr",
          Effect: "Allow",
          Action: [
              "ecr:BatchGetImage",
              "ecr:GetDownloadUrlForLayer",
          ],
          Resource: "012345678901.dkr.ecr.eu-west-1.amazonaws.com/some-repo/busybox",
      }
    ]
  }
  ```

  </details>

Procedure:

1. Configure the default AWS Region for the AWS SDK to use.

   <details style="margin-top: -1em; padding-bottom: 1em;">

   ```ini
   [default]
   region = eu-west-1
   ```

   </details>

   This could probably just be configured in the executor's setting, but I still need to confirm it.

   <details style="margin-top: -1em; padding-bottom: 1em;">

   ```toml
   [[runners]]
     executor = "docker-autoscaler"
     environment = [ "AWS_REGION=eu-west-1" ]
   ```

   </details>

1. Install the gitlab runner on the **manager** instance.<br/>
   Configure it to use the `docker-autoscaler` executor.

   <details style="margin-top: -1em; padding-bottom: 1em;">

   ```toml
   concurrent = 10

   [[runners]]
     name = "docker autoscaler"
     url = "https://gitlab.example.org"
     token = "<token>"
     executor = "docker-autoscaler"

     [runners.docker]
       image = "012345678901.dkr.ecr.eu-west-1.amazonaws.com/some-repo/busybox:latest"

     [runners.autoscaler]
       plugin = "aws"
       max_instances = 10

       [runners.autoscaler.plugin_config]
         name = "my-docker-asg"  # the required ASG name

       [[runners.autoscaler.policy]]
         idle_count = 5
         idle_time = "20m0s"
   ```

   </details>

1. Install the [fleeting] plugin.

   <details style="margin-top: -1em; padding-bottom: 1em;">

   ```sh
   gitlab-runner fleeting install
   ```

   </details>

</details>

### Docker Machine executor

> **Deprecated** in GitLab 17.5.<br/>
> If using this executor with EC2 instances, Azure Compute, or GCE, migrate to the
> [GitLab Runner Autoscaler](#gitlab-runner-autoscaler).

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

  url = "https://gitlab.example.org"
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
      Timezone = "UTC"

      IdleCount = 0
      IdleTime = 120
```

</details>

### Instance executor

Refer [Instance executor](#instance-executor).

Autoscale-enabled executor that creates instances on-demand to accommodate the expected volume of jobs processed by the
runner manager.

Useful when jobs need full access to the host instance, operating system, and attached devices.<br/>
Can be configured to accommodate single and multi-tenant jobs with various levels of isolation and security.

## Autoscaling

Refer [GitLab Runner Autoscaling].

GitLab Runner can automatically scale using public cloud instances when configured to use an autoscaler.

Autoscaling options are available for public cloud instances and the following orchestration solutions:

- OpenShift.
- Kubernetes.
- Amazon ECS clusters using Fargate.

### Docker Machine

Refer [Autoscaling GitLab Runner on AWS EC2].

One or more runners must act as managers, and be configured to use the
[Docker Machine executor](#docker-machine-executor).<br/>
Managers interact with the cloud infrastructure to create multiple runner instances to execute jobs.<br/>
Cloud instances acting as managers shall **not** be spot instances.

### GitLab Runner Autoscaler

Refer [GitLab Runner Autoscaler].

Successor to the [Docker Machine](#docker-machine).

Composed of:

- **Taskscaler**: manages autoscaling logic, bookkeeping, and fleets creations.
- **Fleeting**: abstraction for cloud-provided virtual machines.
- **Cloud provider plugin**: handles the API calls to the target cloud platform.

One or more runners must act as managers.<br/>
Managers interact with the cloud infrastructure to create multiple runner instances to execute jobs.<br/>
Cloud instances acting as managers shall **not** be spot instances.

Managers must be configured to use one or more of the specific executors for autoscaling:

- [Instance executor](#instance-executor).
- [Docker Autoscaling executor](#docker-autoscaler-executor).

### Kubernetes

[Store tokens in secrets][store registration tokens or runner tokens in secrets] instead of putting the token in the
chart's values.

Requirements:

- A running and configured Gitlab instance.
- A running Kubernetes cluster.

<details>
  <summary>Installation procedure</summary>

1. \[best practice] Create a dedicated namespace:

   ```sh
   kubectl create namespace 'gitlab'
   ```

1. Create a runner in gitlab:

   <details>
     <summary>Web UI</summary>

   1. Go to one's Gitlab instance's `/admin/runners` page.
   1. Click on the _New instance runner_ button.
   1. Keep _Linux_ as runner type.
   1. Click on the _Create runner_ button.
   1. Copy the runner's token.

   </details>

   <details style="padding-bottom: 1em;">
     <summary>API</summary>

   ```sh
   curl -X 'POST' 'https://gitlab.example.org/api/v4/user/runners' -H 'PRIVATE-TOKEN: glpat-m-…' \
     -d 'runner_type=instance_type' -d 'tag_list=small,instance' -d 'run_untagged=false' -d 'a runner'
   ```

   </details>

1. (Re-)Create the runners' Kubernetes secret with the runners' token from the previous step:

   ```sh
   kubectl --namespace 'gitlab' delete secret 'gitlab-runner-token' --ignore-not-found
   kubectl --namespace 'gitlab' create secret generic 'gitlab-runner-token' \
     --from-literal='runner-registration-token=""' --from-literal='runner-token=glrt-…'
   ```

1. \[best practice] Be sure to match the runner version with the Gitlab server's:

   ```sh
   helm search repo --versions 'gitlab/gitlab-runner'
   ```

1. Install the helm chart.

   > The secret's name **must** be matched in the helm chart's values file.

   ```sh
   helm --namespace 'gitlab' upgrade --install 'gitlab-runner-manager' \
     --repo 'https://charts.gitlab.io' 'gitlab-runner' --version '0.69.0' \
     --values 'values.yaml' --set 'runners.secret=gitlab-runner-token'
   ```

</details>

<details style="padding-bottom: 1em;">
  <summary>Example helm chart values</summary>

```yaml
gitlabUrl: https://gitlab.example.org/
unregisterRunners: true
concurrent: 20
checkInterval: 3
rbac:
  create: true
metrics:
  enabled: true
runners:
  name: "runner-on-k8s"
  secret: gitlab-runner-token
  config: |
    [[runners]]

      [runners.cache]
        Shared = true

      [runners.kubernetes]
        namespace = "{{.Release.Namespace}}"
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

        [runners.kubernetes.affinity]
          [runners.kubernetes.affinity.node_affinity]
            [runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution]
              [[runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution.node_selector_terms]]
                [[runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution.node_selector_terms.match_expressions]]
                  key = "org.example.reservation/app"
                  operator = "In"
                  values = [ "gitlab" ]
                [[runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution.node_selector_terms.match_expressions]]
                  key = "org.example.reservation/component"
                  operator = "In"
                  values = [ "runner" ]
            [[runners.kubernetes.affinity.node_affinity.preferred_during_scheduling_ignored_during_execution]]
              weight = 1
              [runners.kubernetes.affinity.node_affinity.preferred_during_scheduling_ignored_during_execution.preference]
                [[runners.kubernetes.affinity.node_affinity.preferred_during_scheduling_ignored_during_execution.preference.match_expressions]]
                  key = "eks.amazonaws.com/capacityType"
                  operator = "In"
                  values = [ "ON_DEMAND" ]
        [runners.kubernetes.node_tolerations]
          "reservation/app=gitlab" = "NoSchedule"
          "reservation/component=runner" = "NoSchedule"

affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
            - key: eks.amazonaws.com/capacityType
              operator: In
              values:
                - ON_DEMAND
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

- Keep the manager pod on stable nodes.

  <details style="padding-bottom: 1em;">

  ```yaml
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 1
          preference:
            matchExpressions:
              - key: eks.amazonaws.com/capacityType
                operator: In
                values:
                  - ON_DEMAND
  ```

  </details>

- Dedicate specific nodes to runner executors.<br/>
  Taint dedicated nodes and add tolerations and affinities to the runner's configuration.

  <details style="padding-bottom: 1em;">

  ```toml
  [[runners]]
    [runners.kubernetes]

    [runners.kubernetes.node_selector]
      gitlab = "true"
      "kubernetes.io/arch" = "amd64"

      [runners.kubernetes.affinity]
        [runners.kubernetes.affinity.node_affinity]
          [runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution]
            [[runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution.node_selector_terms]]
              [[runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution.node_selector_terms.match_expressions]]
                key = "app"
                operator = "In"
                values = [ "gitlab-runner" ]
              [[runners.kubernetes.affinity.node_affinity.required_during_scheduling_ignored_during_execution.node_selector_terms.match_expressions]]
                key = "customLabel"
                operator = "In"
                values = [ "customValue" ]

            [[runners.kubernetes.affinity.node_affinity.preferred_during_scheduling_ignored_during_execution]]
              weight = 1

              [runners.kubernetes.affinity.node_affinity.preferred_during_scheduling_ignored_during_execution.preference]
                [[runners.kubernetes.affinity.node_affinity.preferred_during_scheduling_ignored_during_execution.preference.match_expressions]]
                  key = "eks.amazonaws.com/capacityType"
                  operator = "In"
                  values = [ "ON_DEMAND" ]

      [runners.kubernetes.node_tolerations]
        "app=gitlab-runner" = "NoSchedule"
        "node-role.kubernetes.io/master" = "NoSchedule"
        "custom.toleration=value" = "NoSchedule"
        "empty.value=" = "PreferNoSchedule"
        onlyKey = ""
  ```

  </details>

- Avoid massive resource consumption by defaulting to (very?) strict resource limits and `0` request.

  <details style="padding-bottom: 1em;">

  ```toml
  [[runners]]
    [runners.kubernetes]
      cpu_request = "0"
      cpu_limit = "2"
      memory_request = "0"
      memory_limit = "2Gi"
      ephemeral_storage_request = "0"
      ephemeral_storage_limit = "512Mi"

      helper_cpu_request = "0"
      helper_cpu_limit = "0.5"
      helper_memory_request = "0"
      helper_memory_limit = "128Mi"
      helper_ephemeral_storage_request = "0"
      helper_ephemeral_storage_limit = "64Mi"

      service_cpu_request = "0"
      service_cpu_limit = "1"
      service_memory_request = "0"
      service_memory_limit = "0.5Gi"
  ```

  </details>

- Play nice and make sure to leave some space for the host's other workloads by allowing for resource request and limit
  override only up to a point.

  <details style="padding-bottom: 1em;">

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

## Further readings

- [Gitlab]
- [Amazon ECR Docker Credential Helper]
- Gitlab's [docker machine] fork
- Gitlab's [gitlab-runner-operator] for OpenShift and Kubernetes
- [Docker Machine Executor autoscale configuration]
- [Fleeting]

### Sources

- [Install Gitlab runner]
- [Docker executor]
- [Authenticating your GitLab CI runner to an AWS ECR registry using Amazon ECR Docker Credential Helper]
- [Install and register GitLab Runner for autoscaling with Docker Machine]
- [AWS driver does not support multiple non default subnets]
- [GitLab Runner Helm Chart]
- [GitLab Runner Autoscaling]
- [Autoscaling GitLab Runner on AWS EC2]
- [Instance executor]
- [Docker Autoscaler executor]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[gitlab]: README.md

<!-- Files -->
<!-- Upstream -->
[autoscaling gitlab runner on aws ec2]: https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/
[docker autoscaler executor]: https://docs.gitlab.com/runner/executors/docker_autoscaler.html
[docker executor]: https://docs.gitlab.com/runner/executors/docker.html
[docker machine executor autoscale configuration]: https://docs.gitlab.com/runner/configuration/autoscale.html
[docker machine's aws driver's options]: https://gitlab.com/gitlab-org/ci-cd/docker-machine/-/blob/main/docs/drivers/aws.md#options
[docker machine's supported cloud providers]: https://docs.gitlab.com/runner/configuration/autoscale.html#supported-cloud-providers
[docker machine]: https://gitlab.com/gitlab-org/ci-cd/docker-machine
[fleeting]: https://gitlab.com/gitlab-org/fleeting/fleeting
[gitlab runner autoscaler]: https://docs.gitlab.com/runner/runner_autoscale/index.html#gitlab-runner-autoscaler
[gitlab runner autoscaling]: https://docs.gitlab.com/runner/runner_autoscale/
[gitlab runner helm chart]: https://docs.gitlab.com/runner/install/kubernetes.html
[gitlab-runner-operator]: https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator
[install and register gitlab runner for autoscaling with docker machine]: https://docs.gitlab.com/runner/executors/docker_machine.html
[install gitlab runner]: https://docs.gitlab.com/runner/install/
[instance executor]: https://docs.gitlab.com/runner/executors/instance.html
[store registration tokens or runner tokens in secrets]: https://docs.gitlab.com/runner/install/kubernetes.html#store-registration-tokens-or-runner-tokens-in-secrets

<!-- Others -->
[authenticating your gitlab ci runner to an aws ecr registry using amazon ecr docker credential helper]: https://faun.pub/authenticating-your-gitlab-ci-runner-to-an-aws-ecr-registry-using-amazon-ecr-docker-credential-b4604a9391eb
[aws driver does not support multiple non default subnets]: https://github.com/docker/machine/issues/4700
[amazon ecr docker credential helper]: https://github.com/awslabs/amazon-ecr-credential-helper
