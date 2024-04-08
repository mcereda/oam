# Gitlab

1. [Omnibus](#omnibus)
1. [Kubernetes](#kubernetes)
   1. [Helm chart](#helm-chart)
   1. [Operator](#operator)
1. [CI/CD pipelines](#cicd-pipelines)
   1. [Make a job in a pipeline run only when some specific files change](#make-a-job-in-a-pipeline-run-only-when-some-specific-files-change)
   1. [Get the version of the helper image to use for a runner](#get-the-version-of-the-helper-image-to-use-for-a-runner)
1. [Manage kubernetes clusters](#manage-kubernetes-clusters)
1. [Runners](#runners)
   1. [Autoscaling](#autoscaling)
      1. [Docker Machine](#docker-machine)
1. [Troubleshooting](#troubleshooting)
   1. [Use access tokens to clone projects](#use-access-tokens-to-clone-projects)
   1. [Pipeline fails with error `You are not allowed to download code from this project`](#pipeline-fails-with-error-you-are-not-allowed-to-download-code-from-this-project)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## Omnibus

<details>
  <summary>Configuration</summary>

The application of configuration changes is handled by [Chef Infra].<br/>
It runs checks, ensures directories, permissions, and services are in place and working, and restarts components if any
of their configuration files have changed.

```sh
# Edit and validate.
sudo vim '/etc/gitlab/gitlab.rb'
sudo ruby -c '/etc/gitlab/gitlab.rb'
sudo gitlab-ctl check-config

# Make Gitlab aware of the changes.
sudo gitlab-ctl reconfigure
```

Backup settings for AWS buckets.</br>
See [Back up Gitlab using Amazon S3]:

```rb
# If using an IAM Profile, don't configure 'aws_access_key_id' and
# 'aws_secret_access_key' but set "'use_iam_profile' => true" instead.
gitlab_rails['backup_upload_connection'] = {
  'provider' => 'AWS',
  'region' => 'eu-west-1',
  'aws_access_key_id' => 'AKIAKIAKI',
  'aws_secret_access_key' => 'secret123'
}

# It appears one can use prefixes by appending them to the bucket name.
# See https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3376.
gitlab_rails['backup_upload_remote_directory'] = 'bucket-name/prefix'

# Use multipart uploads when the archive's size exceeds 100MB.
gitlab_rails['backup_multipart_chunk_size'] = 104857600

# Only keep 7 days worth of backups.
gitlab_rails['backup_keep_time'] = 604800
```

</details>

<details>
  <summary>Maintenance</summary>

```sh
# Check the components' state.
sudo gitlab-ctl status

# Create backups.
sudo gitlab-backup create BACKUP='prefix_override' STRATEGY='copy'

# Create empty backup archives for testing purposes.
# See https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html#excluding-specific-data-from-the-backup
sudo gitlab-backup create … \
  SKIP='db,repositories,uploads,builds,artifacts,pages,lfs,terraform_state,registry,packages,ci_secure_files'
```

</details>

## Kubernetes

### Helm chart

Gitlab offers an official helm chart to to allow for deployments on kubernetes clusters.

Follow the [deployment] guide for details and updated information.

<details>
  <summary>Deployment</summary>

1. Prepare the environment:

   ```sh
   export \
     ENVIRONMENT='minikube' \
     NAMESPACE='gitlab' \
     VALUES_DIR="$(git rev-parse --show-toplevel)/kubernetes/helm/gitlab"
   ```

1. Validate the values and install the chart.

   > The installation took > 20m on a MacBook Pro 16-inch 2019 with Intel i7 and 16GB RAM.

   ```sh
   # validation
   helm upgrade --install \
     --namespace "${NAMESPACE}" \
     --values "${VALUES_DIR}/values.${ENVIRONMENT}.yaml" \
     'gitlab' \
     'gitlab/gitlab' \
     --dry-run

   # installation
   helm upgrade --install \
     --atomic \
     --create-namespace \
     --namespace "${NAMESPACE}" \
     --timeout 0 \
     --values "${VALUES_DIR}/values.${ENVIRONMENT}.yaml" \
     'gitlab' \
     'gitlab/gitlab' \
     --debug
   ```

1. Keep an eye on the installation:

   ```sh
   kubectl get events \
     --namespace "${NAMESPACE}" \
     --sort-by '.metadata.creationTimestamp' \
     --watch

   # requires `watch` from 'procps-ng'
   # `brew install watch`
   watch kubectl get all --namespace "${NAMESPACE}"

   # requires `k9s`
   # `brew install k9s`
   k9s --namespace "${NAMESPACE}"
   ```

1. Get the login password for the `root` user:

   ```sh
   kubectl get secret 'gitlab-gitlab-initial-root-password' \
     --namespace "${NAMESPACE}" \
     -o jsonpath='{.data.password}' \
   | base64 --decode
   ```

1. Open the login page:

   ```sh
   export URL="https://$(kubectl get ingresses --namespace 'gitlab' | grep 'webservice' | awk '{print $2}')"

   xdg-open "${URL}"   # on linux
   open "${URL}"       # on mac os x
   ```

1. Have fun!

To delete everything:

```sh
helm uninstall --namespace "${NAMESPACE}" 'gitlab'
kubectl delete --ignore-not-found namespace "${NAMESPACE}"
```

</details>

<details>
  <summary>Maintenance</summary>

- Add and update Gitlab's helm repository:

  ```sh
  helm repo add 'gitlab' 'https://charts.gitlab.io/'
  helm repo update
  ```

- Look up the chart's version:

  ```sh
  $ helm search repo 'gitlab/gitlab'
  NAME             CHART VERSION   APP VERSION     DESCRIPTION
  gitlab/gitlab    4.9.3           13.9.3          Web-based Git-repository manager with wiki and ...
  ```

- Fetch the chart:

  ```sh
  helm fetch 'gitlab/gitlab' --untar --untardir "$CHART_DIR"
  helm fetch 'gitlab/gitlab' --untar --untardir "$CHART_DIR" --version "$CHART_VERSION"
  ```

- Get the default values for the chart:

  ```sh
  helm inspect values 'gitlab/gitlab' > "${VALUES_DIR}/values.yaml"
  helm inspect values --version "$CHART_VERSION" 'gitlab/gitlab' > "${VALUES_DIR}/values-${CHART_VERSION}.yaml"
  ```

  ```sh
  export VALUES_DIR="$(git rev-parse --show-toplevel)/kubernetes/helm/gitlab"
  helm inspect values 'gitlab/gitlab' > "${VALUES_DIR}/values.yaml"
  ```

- Create a dedicated values file with the changes one needs (see the helm chart gotchas below):

  ```yaml
  global:
    edition: ce
    ingress:
      configureCertmanager: false
    time_zone: UTC
  certmanager:
    install: false
  gitlab-runner:
    install: false
  ```

- Upgrade the stored chart to a new version:

  ```sh
  helm repo update
  rm -r "${CHART_DIR}/gitlab"
  helm fetch 'gitlab/gitlab' --untar --untardir "$CHART_DIR" --version "$CHART_VERSION"
  ```

</details>

<details>
  <summary>Minikube</summary>

When testing with a minikube installation with 8GiB RAM, kubernetes complained being out of memory.<br/>
Be sure to give your cluster enough resources:

```sh
# on linux
minikube start --kubernetes-version "${K8S_VERSION}" --cpus '4' --memory '12GiB'

# on mac os x
minikube start --kubernetes-version "${K8S_VERSION}" --cpus '8' --memory '12GiB'       # docker-desktop (no Ingresses)
minikube start --kubernetes-version "${K8S_VERSION}" --cpus '8' --memory '12GiB' --vm  # hyperkit vm (to be able to use Ingresses)
```

or consider using the [minimal Minikube example values file] as reference, as stated in [CPU and RAM Resource Requirements](https://docs.gitlab.com/charts/installation/deployment.html#cpu-and-ram-resource-requirements)

1. Finish preparing the environment:

   ```sh
   export K8S_VERSION='v1.16.15'
   ```

1. Enable the `ingress` and `metrics-server` addons:

   ```sh
   minikube addons enable 'ingress'
   minikube addons enable 'metrics-server'
   ```

1. When using the `LoadBalancer` Ingress type (the default), start a tunnel in a different shell to let the installation finish:

   ```sh
   minikube tunnel -c
   ```

1. Install the chart as described above.

1. Add minikube's IP address to the `/etc/hosts` file:

   ```sh
   kubectl get ingresses --namespace 'gitlab' | grep 'webservice' | awk '{print $3 "  " $2}' | sudo tee -a '/etc/hosts'
   ```

</details>

<details>
  <summary>Gotchas</summary>

- Use self-signed certs and avoid using certmanager setting up the following:

  ```yaml
  global:
    ingress:
      configureCertmanager: false
  certmanager:
    install: false
  ```

- Avoid using a load balancer (mainly for local testing) setting the ingress type to `NodePort`:

  ```yaml
  nginx-ingress:
    controller:
      service:
        type: NodePort
  ```

- As of 2021-01-15, a clean minikube cluster with only gitlab installed takes up about 1 vCPU and 6+ GiB RAM:

  ```sh
  $ kubectl top nodes
  NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
  minikube   965m         12%    6375Mi          53%
  ```

  ```sh
  $ kubectl get pods --namespace 'gitlab'
  NAMESPACE     NAME                                                   READY   STATUS        RESTARTS   AGE
  gitlab        gitlab-gitaly-0                                        1/1     Running       0          71m
  gitlab        gitlab-gitlab-exporter-547cf7fbff-xzqjp                1/1     Running       0          71m
  gitlab        gitlab-gitlab-shell-5c5b8dd9cd-g4z7b                   1/1     Running       0          71m
  gitlab        gitlab-gitlab-shell-5c5b8dd9cd-ppbtk                   1/1     Running       0          71m
  gitlab        gitlab-migrations-2-j6lt6                              0/1     Completed     0          8m27s
  gitlab        gitlab-minio-6dd7d96ddb-xxq9w                          1/1     Running       0          71m
  gitlab        gitlab-minio-create-buckets-2-q5zfg                    0/1     Completed     0          8m27s
  gitlab        gitlab-nginx-ingress-controller-7fc8cbf49d-b9lqm       1/1     Running       0          71m
  gitlab        gitlab-nginx-ingress-controller-7fc8cbf49d-ng589       1/1     Running       0          71m
  gitlab        gitlab-nginx-ingress-default-backend-7ff88b95f-lv5vt   1/1     Running       0          71m
  gitlab        gitlab-postgresql-0                                    2/2     Running       0          71m
  gitlab        gitlab-prometheus-server-6cfb57f575-cs669              2/2     Running       0          71m
  gitlab        gitlab-redis-master-0                                  2/2     Running       0          71m
  gitlab        gitlab-registry-6c75496fc7-fgbvb                       1/1     Running       0          8m16s
  gitlab        gitlab-registry-6c75496fc7-fhsqs                       1/1     Running       0          8m27s
  gitlab        gitlab-sidekiq-all-in-1-v1-64b9c56675-lf29p            1/1     Running       0          8m27s
  gitlab        gitlab-task-runner-7897bb897d-br5g5                    1/1     Running       0          7m54s
  gitlab        gitlab-webservice-default-7846fb55d6-4pspg             2/2     Running       0          7m37s
  gitlab        gitlab-webservice-default-7846fb55d6-tmjqm             2/2     Running       0          8m27s
  ```

  with a **spike** of 5 vCPUs upon installation (specially for sidekiq). Keep this in mind when sizing the test cluster

- Disable TLS setting up the following values:

  ```yaml
  global:
    hosts:
      https: false
    ingress:
      tls:
        enabled: false
  ```

- Use a suffix in the ingresses hosts setting up the `global.hosts.hostSuffix` value:

  ```sh
  $ helm template \
      --namespace "${NAMESPACE}" \
      --values "${VALUES_DIR}/values.${ENVIRONMENT}.yaml" \
      --set global.hosts.hostSuffix='test' \
      'gitlab' \
      'gitlab/gitlab' \
    | yq -r 'select(.kind == "Ingress") | .spec.rules[].host' -

  gitlab-test.f.q.dn
  minio-test.f.q.dn
  registry-test.f.q.dn
  ```

</details>

### Operator

See the [operator guide] and the [operator code] for details.

## CI/CD pipelines

Refer to [CI/CD pipelines].

### Make a job in a pipeline run only when some specific files change

Use the `only` and `except` keywords to specify a condition to run. Alternatively, use the `rules` keyword.

> The `only`/`except` keywords have been deprecated by the `rules` keyword, and cannot be used together. This means you might be forced to use `only`/`except` if you are including a pipeline that is already using them.

Let's use a job named `docker-build` as example:

```yaml
docker-build:
  only:
    changes:
      - cmd/*
      - go.*
      - Dockerfile
```

Multiple entries in the condition are validated in an `OR` fashion. In this example, the condition will make the job run only when a change occurs:

- to any file in the `cmd` directory
- to any file in the repository's root directory which name starts with `go` (like `go.mod` or `go.sum`)
- to the `Dockerfile` in the repository's root directory

### Get the version of the helper image to use for a runner

The `gitlab/gitlab-runner-helper` images are tagged using the runner's **os**, **architecture**, and **git revision**.

One needs to know the version of Gitlab and of the runner one wants to use.
Usually, the runner's version is the one most similar to Gitlab's version (e.g. Gitlab: 13.6.2 → gitlab-runner: 13.6.0).

To get the tag to use for the helper, check the runner's version:

```sh
$ docker run --rm --name 'runner' 'gitlab/gitlab-runner:alpine-v13.6.0' --version
Version:      13.6.0
Git revision: 8fa89735
Git branch:   13-6-stable
GO version:   go1.13.8
Built:        2020-11-21T06:16:31+0000
OS/Arch:      linux/amd64
```

In this case, the os is _Linux_, the architecture is _amd64_ and the revision is _8fa89735_. So, following their instructions, the tag will be _x86_64-8fa89735_:

```sh
$ docker pull 'gitlab/gitlab-runner-helper:x86_64-8fa89735'
x86_64-8fa89735: Pulling from gitlab/gitlab-runner-helper
a1514ca1e64d: Pull complete
Digest: sha256:4e239257280eb0fa750f1ef30975dacdef5f5346bfaa9e6d60e58d440d8cd0f1
Status: Downloaded newer image for gitlab/gitlab-runner-helper:x86_64-8fa89735
docker.io/gitlab/gitlab-runner-helper:x86_64-8fa89735
```

## Manage kubernetes clusters

See [adding and removing kubernetes clusters] for more information.

For now the Gitlab instance can manage only kubernetes clusters external to the one it is running into.

## Runners

```sh
brew install 'gitlab-runner'
```

```sh
gitlab-runner exec docker 'job-name'
gitlab-runner exec docker \
  --env 'AWS_ACCESS_KEY_ID=AKIA…' --env 'AWS_SECRET_ACCESS_KEY=F…s' --env 'AWS_REGION=eu-east-1' \
  --env 'DOCKER_AUTH_CONFIG={ "credsStore": "ecr-login" }' \
  --docker-volumes "$HOME/.aws/credentials:/root/.aws/credentials:ro"
  'job-requiring-ecr-access'
```

### Autoscaling

#### Docker Machine

[Supported cloud providers][docker machine's supported cloud providers].

Pitfalls:

- On AWS, the driver supports only one subnet.<br/>
  See [AWS driver does not support multiple non default subnets] and [Docker Machine's AWS driver's options].

## Troubleshooting

### Use access tokens to clone projects

```sh
git clone "https://oauth2:${ACCESS_TOKEN}@somegitlab.com/vendor/package.git"
```

### Pipeline fails with error `You are not allowed to download code from this project`

Error message example:

```txt
Getting source from Git repository 00:00
Fetching changes with git depth set to 20...
Reinitialized existing Git repository in /builds/myProj/myRepo/.git/
remote: You are not allowed to download code from this project.
fatal: unable to access 'https://gitlab.com/myProj/myRepo.git/': The requested URL returned error: 403
```

Root cause: the user starting the pipeline does not have enough privileges to the repository.

Solution: give that user _developer_ access or have somebody else with enough privileges run it.

## Further readings

- Gitlab's helm [chart]
- Gitlab's helm [chart]'s [global settings]
- [Command-line options]
- [Deployment] guide
- Install [runners on kubernetes]
- [TLS] configuration
- [Adding and removing Kubernetes clusters]
- Gitlab's [operator code] and relative [guide][operator guide]
- [CI/CD pipelines]

### Sources

- [Configuring private dns zones and upstream nameservers in kubernetes]
- [Using GitLab token to clone without authentication]
- [Back up GitLab Using Amazon S3]
- [Support object storage bucket prefixes]
- [Back up GitLab excluding specific data from the backup]
- [AWS driver does not support multiple non default subnets]
- [Autoscaling GitLab Runner on AWS EC2]
- [Authenticating your GitLab CI runner to an AWS ECR registry using Amazon ECR Docker Credential Helper]
- [How to restart GitLab]
- [Customize pipeline configuration]

<!--
  References
  -->

<!-- Upstream -->
[adding and removing kubernetes clusters]: https://docs.gitlab.com/ee/user/project/clusters/add_remove_clusters.html
[autoscaling gitlab runner on aws ec2]: https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/
[back up gitlab excluding specific data from the backup]: https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html#excluding-specific-data-from-the-backup
[back up gitlab using amazon s3]: https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html?tab=Linux+package+%28Omnibus%29#using-amazon-s3
[chart]: https://docs.gitlab.com/charts/
[ci/cd pipelines]: https://docs.gitlab.com/ee/ci/pipelines/
[command-line options]: https://docs.gitlab.com/charts/installation/command-line-options.html
[customize pipeline configuration]: https://docs.gitlab.com/ee/ci/pipelines/settings.html
[deployment]: https://docs.gitlab.com/charts/installation/deployment.html
[docker machine's aws driver's options]: https://gitlab.com/gitlab-org/ci-cd/docker-machine/-/blob/main/docs/drivers/aws.md#options
[docker machine's supported cloud providers]: https://docs.gitlab.com/runner/configuration/autoscale.html#supported-cloud-providers
[global settings]: https://docs.gitlab.com/charts/charts/globals.html
[how to restart gitlab]: https://docs.gitlab.com/ee/administration/restart_gitlab.html
[minimal minikube example values file]: https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/values-minikube-minimum.yaml
[operator code]: https://gitlab.com/gitlab-org/cloud-native/gitlab-operator
[operator guide]: https://docs.gitlab.com/operator/
[runners on kubernetes]: https://docs.gitlab.com/runner/install/kubernetes.html
[support object storage bucket prefixes]: https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3376
[tls]: https://docs.gitlab.com/charts/installation/tls.html

<!-- Others -->
[authenticating your gitlab ci runner to an aws ecr registry using amazon ecr docker credential helper]: https://faun.pub/authenticating-your-gitlab-ci-runner-to-an-aws-ecr-registry-using-amazon-ecr-docker-credential-b4604a9391eb
[aws driver does not support multiple non default subnets]: https://github.com/docker/machine/issues/4700
[chef infra]: https://www.chef.io/products/chef-infra
[configuring private dns zones and upstream nameservers in kubernetes]: https://kubernetes.io/blog/2017/04/configuring-private-dns-zones-upstream-nameservers-kubernetes/
[using gitlab token to clone without authentication]: https://stackoverflow.com/questions/25409700/using-gitlab-token-to-clone-without-authentication#29570677
