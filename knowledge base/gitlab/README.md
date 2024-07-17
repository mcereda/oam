# Gitlab

1. [TL;DR](#tldr)
1. [Package](#package)
1. [Kubernetes](#kubernetes)
   1. [Helm chart](#helm-chart)
   1. [Operator](#operator)
1. [Repository management](#repository-management)
   1. [Different owners for parts of the code base](#different-owners-for-parts-of-the-code-base)
   1. [Get the version of the helper image to use for a runner](#get-the-version-of-the-helper-image-to-use-for-a-runner)
1. [Manage kubernetes clusters](#manage-kubernetes-clusters)
1. [Maintenance mode](#maintenance-mode)
1. [Runners](#runners)
1. [CI/CD pipelines](#cicd-pipelines)
1. [Troubleshooting](#troubleshooting)
   1. [Use access tokens to clone projects](#use-access-tokens-to-clone-projects)
   1. [Gitlab keeps answering with code 502](#gitlab-keeps-answering-with-code-502)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

Using `-H 'PRIVATE-TOKEN: glpat-m-…'` in API calls is the same as using `-H 'Authorization: bearer glpat-m-…'`.

```sh
# List the current application settings of the GitLab instance.
curl -H 'PRIVATE-TOKEN: glpat-m-…' 'https://gitlab.fqdn/api/v4/application/settings'

# Enable maintenance mode.
curl -X 'PUT' -H 'PRIVATE-TOKEN: glpat-m-…' 'https://gitlab.fqdn/api/v4/application/settings?maintenance_mode=true'

# Disable maintenance mode.
curl -X 'PUT' -H 'PRIVATE-TOKEN: glpat-m-…' 'https://gitlab.fqdn/api/v4/application/settings?maintenance_mode=false'
```

## Package

Previously known as 'Omnibus'.

Default backup location: `/var/opt/gitlab/backups`.

<details>
  <summary>Installation</summary>

Refer [Install self-managed GitLab].

```sh
sudo dnf install 'gitlab-ee'
sudo EXTERNAL_URL='http://gitlab.example.com' GITLAB_ROOT_PASSWORD='smthng_Strong_0r_it_llfail' apt install 'gitlab-ee'

sudo gitlab-rake 'gitlab:env:info'
```

</details>
<details>
  <summary>Configuration</summary>

[Template][package configuration file template]

The application of configuration changes is handled by [Chef Infra].<br/>
It runs checks, ensures directories, permissions, and services are in place and working, and restarts components if any
of their configuration files have changed.

```sh
# Change application settings.
# Useful to reach those ones not available in the configuration file.
sudo gitlab-rails runner '
  ::Gitlab::CurrentSettings.update!(gravatar_enabled: false);
  ::Gitlab::CurrentSettings.update!(remember_me_enabled: false);
  ::Gitlab::CurrentSettings.update!(email_confirmation_setting: "hard");
'

# Disable public registration.
sudo gitlab-rails runner '::Gitlab::CurrentSettings.update!(signup_enabled: false)'
```

```sh
# Validate.
# Just makes sure the file is readable from a ruby app.
# Gitlab's internal checks do not really do anything.
sudo vim '/etc/gitlab/gitlab.rb'
sudo ruby -c '/etc/gitlab/gitlab.rb'
sudo gitlab-ctl show-config

# Check if there are any configuration in the configuration file that is removed in specified versions.
# Useless by experience.
sudo gitlab-ctl check-config
sudo gitlab-ctl check-config -v '16.11.0'

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

The package's included nginx generates keys and a **self-signed** certificate for the external URL upon start if the
given URL's schema is HTTPS.<br/>
The Let's Encrypt account key is in OpenSSL format, while the certificate's key is in OpenSSH format. Both are **not**
password protected.

</details>

<details>
  <summary>Maintenance</summary>

```sh
# Check the components' state.
sudo gitlab-ctl status

# Get the services' logs.
sudo gitlab-ctl tail
sudo gitlab-ctl tail 'nginx'

# Restart services.
sudo gitlab-ctl restart
sudo gitlab-ctl restart 'nginx'

# Run checks for the whole system.
sudo gitlab-rake 'gitlab:check'

# Create backups.
sudo gitlab-backup create
sudo gitlab-backup create BACKUP='prefix_override' STRATEGY='copy'

# Create empty backup archives for testing purposes.
# See https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html#excluding-specific-data-from-the-backup
sudo gitlab-backup create … \
  SKIP='db,repositories,uploads,builds,artifacts,pages,lfs,terraform_state,registry,packages,ci_secure_files'

# Create backups of the configuration.
sudo gitlab-ctl backup-etc
sudo gitlab-ctl backup-etc && ls -t '/etc/gitlab/config_backup/' | head -n '1'

# Restore backups.
sudo aws s3 cp 's3://backups/gitlab/gitlab-secrets.json' '/etc/gitlab/gitlab-secrets.json' \
&& sudo aws s3 cp 's3://backups/gitlab/gitlab.rb' '/etc/gitlab/gitlab.rb' \
&& sudo aws s3 cp \
  's3://backups/gitlab/11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar' \
  '/var/opt/gitlab/backups/' \
&& sudo gitlab-ctl stop 'puma' \
&& sudo gitlab-ctl stop 'sidekiq' \
&& sudo GITLAB_ASSUME_YES=1 gitlab-backup restore BACKUP='11493107454_2018_04_25_10.6.4-ce' \
&& sudo gitlab-ctl restart \
&& sudo gitlab-rake 'gitlab:check' SANITIZE=true \
&& sudo gitlab-rake 'gitlab:doctor:secrets' \
&& sudo gitlab-rake 'gitlab:artifacts:check' \
&& sudo gitlab-rake 'gitlab:lfs:check' \
&& sudo gitlab-rake 'gitlab:uploads:check'

# Upgrade the package.
sudo yum check-update
sudo gitlab-backup create
tmux new-session -As 'gitlab-upgrade' "sudo yum update 'gitlab-ee'"

# Reset the root user's password.
sudo gitlab-rake 'gitlab:password:reset[root]'
sudo gitlab-rails console  \
  # --> user = User.find_by_username 'root'
  # --> user.password = 'QwerTy184'
  # --> user.password_confirmation = 'QwerTy184'
  # --> user.password_automatically_set = false
  # --> user.save!
  # --> quit
sudo gitlab-rails runner '
  user = User.find_by_username "anUsernameHere";
  new_password = "QwerTy184";
  user.password = new_password;
  user.password_confirmation = new_password;
  user.password_automatically_set = false;
  user.save!
'

# Disable users' two factor authentication.
sudo gitlab-rails runner 'User.where(username: "anUsernameHere").each(&:disable_two_factor!)'
```

Migration procedure:

1. Put the old instance in [maintenance mode]
1. Take a full backup of the old instance
1. Copy the configuration and secrets from the old instance to the new one
1. Change the DNS to the new instance
1. Reconfigure the new instance
1. Restore the full backup on the new instance

</details>

<details>
  <summary>Removal</summary>

Refer <https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/doc/installation/index.md#uninstall-the-linux-package-omnibus>.

```sh
# Remove all users and groups created by the package.
sudo gitlab-ctl stop && sudo gitlab-ctl remove-accounts

# Remove all data.
sudo gitlab-ctl cleanse && sudo rm -r '/opt/gitlab'

# Uninstall the package.
sudo apt remove 'gitlab-ee'
sudo dnf remove 'gitlab-ee'
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

or consider using the [minimal Minikube example values file] as reference, as stated in
[CPU and RAM Resource Requirements][chart cpu and ram resource requirements]

1. Finish preparing the environment:

   ```sh
   export K8S_VERSION='v1.16.15'
   ```

1. Enable the `ingress` and `metrics-server` addons:

   ```sh
   minikube addons enable 'ingress'
   minikube addons enable 'metrics-server'
   ```

1. When using the `LoadBalancer` Ingress type (the default), start a tunnel in a different shell to let the installation
   finish:

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

## Repository management

### Different owners for parts of the code base

Refer to [code owners] for more and updated information.

Leverage _code owners_.

By adding code owners to the repository, they become eligible approvers in the project for MRs that contain those files.
<br/>
Enable the _eligible approvers_ merge request approval rule in the project's _Settings_ > _Merge requests_.

> Require code owner approval for protected branches in the project's _Settings_ > _Repository_ > _Protected branches_.

Gotchas:

- Specifying owners for paths **overwrites** the previous owners list.<br/>
  There seems to be no way to **inherit and add** (and not just overwrite) owners that would not require the list being
  repeated.
- There is as of 2024-04-10 no way to assign ownership by using aliases for roles (like maintainers or developers); only
  groups or users are allowed.<br/>
  This feature is being added, but it has been open for over 3y now. See
  [Ability to reference Maintainers or Developers from CODEOWNERS].

### Get the version of the helper image to use for a runner

The `gitlab/gitlab-runner-helper` images are tagged using the runner's **os**, **architecture**, and **git revision**.

One needs to know the version of Gitlab and of the runner one wants to use.<br/>
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

In this case, the os is _Linux_, the architecture is _amd64_ and the revision is _8fa89735_. So, following their
instructions, the tag will be _x86_64-8fa89735_:

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

## Maintenance mode

Refer [Gitlab maintenance mode].

Allows administrators to reduce write operations to a minimum while maintenance tasks are performed.<br/>
The main goal is to block all external actions that change the internal state, specially the PostgreSQL database, files,
repositories, and the container registry.

When enabled, new actions are forbidden to come in and internal state changes are minimal.<br/>
This allows maintenance tasks to execute easier as services can be stopped completely or further degraded for a shorter
period of time than might otherwise be needed.

Most external actions that do **not** change the internal state are allowed. HTTP `POST`, `PUT`, `PATCH`, and `DELETE`
requests are blocked.<br/>
See <https://docs.gitlab.com/ee/administration/maintenance_mode/#rest-api> for a detailed overview of how special cases
are handled.

Through Web UI:

- On the left sidebar, at the bottom, select _Admin Area_.
- On the left sidebar, select _Settings_ > _General_.
- Expand _Maintenance Mode_ and toggle _Enable Maintenance Mode_.<br/>
  Optionally add a message for the banner.
- Select _Save changes_.

Through API calls:

```sh
# Enable maintenance mode.
curl -X 'PUT' -H 'PRIVATE-TOKEN: glpat-m-…' 'https://gitlab.fqdn/api/v4/application/settings?maintenance_mode=true'
curl -X 'PUT' -H 'PRIVATE-TOKEN: glpat-m-…' \
  'https://gitlab.fqdn/api/v4/application/settings?maintenance_mode_message=YaBlockedBro'
```

```sh
# Disable maintenance mode.
curl -X 'PUT' -H 'PRIVATE-TOKEN: glpat-m-…' 'https://gitlab.fqdn/api/v4/application/settings?maintenance_mode=false'
```

Through Rails console:

```ruby
::Gitlab::CurrentSettings.update!(maintenance_mode: true)
::Gitlab::CurrentSettings.update!(maintenance_mode_message: "New message")
```

```ruby
::Gitlab::CurrentSettings.update!(maintenance_mode: false)
```

## Runners

See [runners](runner.md).

## CI/CD pipelines

See [pipelines](pipeline.md).

## Troubleshooting

### Use access tokens to clone projects

```sh
git clone "https://oauth2:${ACCESS_TOKEN}@somegitlab.com/vendor/package.git"
```

### Gitlab keeps answering with code 502

Refer [The docker images for gitlab-ce and gitlab-ee start workhorse with incorrect socket ownership].

Error message example:

> ==> /var/log/gitlab/nginx/gitlab_error.log <==<br/>
> 2024/05/09 20:57:57 \[crit] 617#0: *26 connect() to unix:/var/opt/gitlab/gitlab-workhorse/sockets/socket failed (13:
> Permission denied) while connecting to upstream, client: 172.21.0.1, server: gitlab.lan, request: "GET / HTTP/2.0",
> upstream: "http\://unix:/var/opt/gitlab/gitlab-workhorse/sockets/socket:/", host: "gitlab.lan:8443"

Context: Gitlab 16.11.2 CE running from Docker image.

Root cause: the socket's permissions are mapped incorrectly.

Solution: set the correct ownership with
`docker exec 'gitlab' chown 'gitlab-www:git' '/var/opt/gitlab/gitlab-workhorse/sockets/socket'`.

## Further readings

- [Self-hosting]
- Gitlab's helm [chart]
- Gitlab's helm [chart]'s [global settings]
- [Command-line options]
- [Deployment] guide
- Install [runners on kubernetes]
- [TLS] configuration
- [Adding and removing Kubernetes clusters]
- Gitlab's [operator code] and relative [guide][operator guide]
- [Buildah]
- [Kaniko]
- [The GitLab Handbook]
- [Icons]

### Sources

- [Configuring private dns zones and upstream nameservers in kubernetes]
- [Using GitLab token to clone without authentication]
- [Back up GitLab Using Amazon S3]
- [Support object storage bucket prefixes]
- [Back up GitLab excluding specific data from the backup]
- [Autoscaling GitLab Runner on AWS EC2]
- [How to restart GitLab]
- [Code owners]
- [Ability to reference Maintainers or Developers from CODEOWNERS]
- [Merge request approval rules]
- [Caching in CI/CD]
- [Tutorial: Use Buildah in a rootless container with GitLab Runner Operator on OpenShift]
- [Use kaniko to build Docker images]
- [Install self-managed GitLab]
- [Package configuration file template]
- [Install GitLab with the Linux package]
- [Reset a user's password]
- [Environment variables]
- [Sign-up restrictions]
- [Restore GitLab]
- [How to disable the Two-factor authentication in GitLab?]
- [How to Upgrade Your Omnibus GitLab]
- [The docker images for gitlab-ce and gitlab-ee start workhorse with incorrect socket ownership]
- [GitLab HA Scaling Runner Vending Machine for AWS EC2 ASG]
- [GitLab maintenance mode]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[maintenance mode]: #maintenance-mode

<!-- Knowledge base -->
[buildah]: ../buildah.md
[kaniko]: ../kubernetes/kaniko.placeholder
[self-hosting]: ../self-hosting.md

<!-- Files -->
<!-- Upstream -->
[ability to reference maintainers or developers from codeowners]: https://gitlab.com/gitlab-org/gitlab/-/issues/282438
[adding and removing kubernetes clusters]: https://docs.gitlab.com/ee/user/project/clusters/add_remove_clusters.html
[autoscaling gitlab runner on aws ec2]: https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/
[back up gitlab excluding specific data from the backup]: https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html#excluding-specific-data-from-the-backup
[back up gitlab using amazon s3]: https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html?tab=Linux+package+%28Omnibus%29#using-amazon-s3
[caching in ci/cd]: https://docs.gitlab.com/ee/ci/caching/
[chart cpu and ram resource requirements]: https://docs.gitlab.com/charts/installation/deployment.html#cpu-and-ram-resource-requirements
[chart]: https://docs.gitlab.com/charts/
[code owners]: https://docs.gitlab.com/ee/user/project/codeowners/
[command-line options]: https://docs.gitlab.com/charts/installation/command-line-options.html
[deployment]: https://docs.gitlab.com/charts/installation/deployment.html
[environment variables]: https://docs.gitlab.com/ee/administration/environment_variables.html
[gitlab ha scaling runner vending machine for aws ec2 asg]: https://gitlab.com/guided-explorations/aws/gitlab-runner-autoscaling-aws-asg#gitlab-runners-on-aws-spot-best-practices
[gitlab maintenance mode]: https://docs.gitlab.com/ee/administration/maintenance_mode/
[global settings]: https://docs.gitlab.com/charts/charts/globals.html
[how to restart gitlab]: https://docs.gitlab.com/ee/administration/restart_gitlab.html
[icons]: https://gitlab-org.gitlab.io/gitlab-svgs/
[install gitlab with the linux package]: https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/doc/installation/index.md
[install self-managed gitlab]: https://about.gitlab.com/install
[merge request approval rules]: https://docs.gitlab.com/ee/user/project/merge_requests/approvals/rules.html
[minimal minikube example values file]: https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/values-minikube-minimum.yaml
[operator code]: https://gitlab.com/gitlab-org/cloud-native/gitlab-operator
[operator guide]: https://docs.gitlab.com/operator/
[package configuration file template]: https://gitlab.com/gitlab-org/omnibus-gitlab/-/raw/master/files/gitlab-config-template/gitlab.rb.template
[reset a user's password]: https://docs.gitlab.com/ee/security/reset_user_password.html
[restore gitlab]: https://docs.gitlab.com/ee/administration/backup_restore/restore_gitlab.html
[runners on kubernetes]: https://docs.gitlab.com/runner/install/kubernetes.html
[sign-up restrictions]: https://docs.gitlab.com/ee/administration/settings/sign_up_restrictions.html
[support object storage bucket prefixes]: https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3376
[the docker images for gitlab-ce and gitlab-ee start workhorse with incorrect socket ownership]: https://gitlab.com/gitlab-org/gitlab/-/issues/349846#note_1516339762
[the gitlab handbook]: https://handbook.gitlab.com/
[tls]: https://docs.gitlab.com/charts/installation/tls.html
[tutorial: use buildah in a rootless container with gitlab runner operator on openshift]: https://docs.gitlab.com/ee/ci/docker/buildah_rootless_tutorial.html
[use kaniko to build docker images]: https://docs.gitlab.com/ee/ci/docker/using_kaniko.html

<!-- Others -->
[chef infra]: https://www.chef.io/products/chef-infra
[configuring private dns zones and upstream nameservers in kubernetes]: https://kubernetes.io/blog/2017/04/configuring-private-dns-zones-upstream-nameservers-kubernetes/
[how to disable the two-factor authentication in gitlab?]: https://stackoverflow.com/questions/31024771/how-to-disable-the-two-factor-authentication-in-gitlab
[how to upgrade your omnibus gitlab]: https://medium.com/kocsistem/how-to-upgrade-your-omnibus-gitlab-9179bb710ca
[using gitlab token to clone without authentication]: https://stackoverflow.com/questions/25409700/using-gitlab-token-to-clone-without-authentication#29570677
