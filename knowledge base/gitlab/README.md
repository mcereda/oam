# GitLab

1. [TL;DR](#tldr)
1. [Package](#package)
1. [Kubernetes](#kubernetes)
   1. [Helm chart](#helm-chart)
   1. [Operator](#operator)
1. [Create resources in GitLab using Pulumi](#create-resources-in-gitlab-using-pulumi)
1. [Forking](#forking)
1. [Repository management](#repository-management)
   1. [Different owners for parts of the code base](#different-owners-for-parts-of-the-code-base)
   1. [Get the version of the helper image to use for a runner](#get-the-version-of-the-helper-image-to-use-for-a-runner)
1. [Manage kubernetes clusters](#manage-kubernetes-clusters)
1. [Maintenance mode](#maintenance-mode)
1. [Runners](#runners)
1. [CI/CD pipelines](#cicd-pipelines)
1. [Artifacts](#artifacts)
    1. [Default artifacts expiration](#default-artifacts-expiration)
    1. [Keep the latest artifacts for all jobs in the latest successful pipelines](#keep-the-latest-artifacts-for-all-jobs-in-the-latest-successful-pipelines)
1. [Login via Google, Github or other services](#login-via-google-github-or-other-services)
1. [Troubleshooting](#troubleshooting)
    1. [Use access tokens to clone projects](#use-access-tokens-to-clone-projects)
    1. [GitLab keeps answering with code 502](#gitlab-keeps-answering-with-code-502)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

Using `-H 'PRIVATE-TOKEN: glpat-m-…'` in API calls is the same as using `-H 'Authorization: bearer glpat-m-…'`.

Use _deploy tokens_ instead of personal access tokens to access repositories in pipelines as they do not expire.

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
sudo dnf install 'gitlab-ee-16.11.6'
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
# GitLab's internal checks do not really do anything.
sudo vim '/etc/gitlab/gitlab.rb'
sudo ruby -c '/etc/gitlab/gitlab.rb'
sudo gitlab-ctl show-config

# Check if there are any configuration in the configuration file that is removed in specified versions.
# Useless by experience.
sudo gitlab-ctl check-config
sudo gitlab-ctl check-config -v '16.11.0'

# Make GitLab aware of the changes.
sudo gitlab-ctl reconfigure
```

Backup settings for AWS buckets.</br>
See [Back up GitLab using Amazon S3]:

```rb
# If using an IAM Profile, don't configure 'aws_access_key_id' and 'aws_secret_access_key'.
# Set "'use_iam_profile' => true" instead.
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

The certificate used by GitLab's nginx should include the full chain.<br/>
The leaf-only certificate works normally, but runners seem to require the full chain to connect properly.

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

# Skip creating tar files during a backup.
# It is *not* possible to skip the tar creation when using object storage for backups.
sudo gitlab-backup create … SKIP='tar'

# Create empty backup archives for testing purposes.
# See https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html#excluding-specific-data-from-the-backup
sudo gitlab-backup create … \
  SKIP='db,repositories,uploads,builds,artifacts,pages,lfs,terraform_state,registry,packages,ci_secure_files'

# Skip backups during upgrades.
sudo touch '/etc/gitlab/skip-auto-backup'

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

# DB version upgrade
sudo gitlab-ctl pg-upgrade
sudo gitlab-ctl pg-upgrade -V '16'
# Check there is enough disk space for two copies of the database
test $(( $(sudo du -s '/var/opt/gitlab/postgresql/data' | awk '{print $1}') * 2 )) -lt \
  $(sudo df --output='avail' --direct '/var/opt/gitlab/postgresql/data' | tail -n 1) \
&& sudo gitlab-ctl pg-upgrade -V '16'

# Reset the root user's password.
sudo gitlab-rake 'gitlab:password:reset[root]'
sudo gitlab-rails console
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

Check the [Upgrade Path tool] before upgrading.

Upgrade procedure:

1. Upgrade to the latest **patch** version of the current minor first.
1. Upgrade to the **latest** patch version of **every** mandatory step.
1. Upgrade runners to the nearest minor version of the main instance.

</details>

<details>
  <summary>Removal</summary>

Refer [Uninstall the Linux Package (Omnibus)].

```sh
# Remove all users and groups created by the package.
sudo gitlab-ctl stop && sudo gitlab-ctl remove-accounts

# Remove all data.
sudo gitlab-ctl cleanse && sudo rm -r '/opt/gitlab'

# Uninstall the package.
sudo apt remove 'gitlab-ce'
sudo dnf remove 'gitlab-ee'
```

</details>

## Kubernetes

### Helm chart

GitLab offers an official helm chart to to allow for deployments on kubernetes clusters.

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

- Add and update GitLab's helm repository:

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

## Create resources in GitLab using Pulumi

Refer Pulumi's [GitLab provider installation & configuration] and [GitLab provider's README].

**Before** it can be used to create resources, Pulumi's GitLab provider **requires**:

- The GitLab instance to be reachable.
- To be [configured][gitlab provider's readme] with the `baseUrl` of the correct GitLab instance:

  ```sh
  # The `baseUrl` configuration value *must* end with a slash.
  pulumi config set 'gitlab:baseUrl' 'https://gitlab.example.com/api/v4/'
  ```

- To be [configured][gitlab provider's readme] with GitLab _administrative_ credentials.

  A token can be set in the stack's configuration.<br/>
  Alternatively, the `GITLAB_TOKEN` environment variable can be exported before updating the project:

  ```sh
  export GITLAB_TOKEN='glpat-m-Va…zy'
  ```

## Forking

Refer [Forks].

## Repository management

### Different owners for parts of the code base

Refer to [Code Owners] and [`CODEOWNERS` syntax][codeowners syntax] for more and updated information.

Leverage _Code Owners_.

Add the `CODEOWNERS` specifying paths and their relative owner.<br/>
Use `@` to specify groups and users. Use `@@` for roles since GitLab 17.8.

<details style="padding-bottom: 1em;">

```plaintext
## Default owners
* @@maintainer

## Default owners + users in the 'customer-support' group
/customerSupport/ @@maintainer @customer-support

## Default owners + users in the 'datascience' group
# @lucas is taking care of it for now too
/ds/ @@maintainer @datascience @lucas
```

</details>

Repositories can use **a single** `CODEOWNERS` file.<br/>
GitLab checks for `CODEOWNERS` files in each repository in these locations **in order**; the **first** one found is the
one that is used, all others are ignored:

- `/CODEOWNERS` (in the repository's root).
- `/docs/CODEOWNERS`.
- `/.gitlab/CODEOWNERS`.

Code Owners specified in the file become eligible approvers in the project for MRs that change files in the specified
file paths.<br/>
Enable the _eligible approvers_ merge request approval rule in the project's _Settings_ > _Merge requests_.

> Require Code Owner approval for protected branches in the project's _Settings_ > _Repository_ > _Protected branches_.

Gotchas:

- Specifying owners for paths **overwrites** the previous owners list.<br/>
  There seems to be no way to **inherit and add** (and not just overwrite) owners that would not require the list being
  repeated.
- ~~There is as of 2024-04-10 no way to assign ownership by using aliases for roles (like maintainers or developers); only
  groups or users are allowed.~~<br/>
  ~~This feature is being added, but it has been open for over 3y now. See
  [Ability to reference Maintainers or Developers from CODEOWNERS].~~<br/>
  Solved in GitLab 17.8, see
  [GitLab 17.8 Release][gitlab 17.8 release - use roles to define project members as code owners].

### Get the version of the helper image to use for a runner

The `gitlab/gitlab-runner-helper` images are tagged using the runner's **os**, **architecture**, and **git revision**.

One needs to know the version of GitLab and of the runner one wants to use.<br/>
Usually, the runner's version is the one most similar to GitLab's version (e.g. GitLab: 13.6.2 → gitlab-runner: 13.6.0).

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

For now the GitLab instance can manage only kubernetes clusters external to the one it is running into.

## Maintenance mode

Refer [GitLab maintenance mode].

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

## Artifacts

GitLab allows to configure a **instance-wide** default expiration for artifacts.<br/>
There is currently **no way** to set up artifacts expiration group-wise or project-wise.

All latest jobs' artifacts are kept by default.<br/>
The rest of them expire:

- As manually configured in the pipeline, or

  <details style="padding-bottom: 1em;">

  ```yaml
  default:
    artifacts:
      expire_in: 1 week

  someJob:
    artifacts:
      expire_in: 1 month
  ```

  </details>

- As configured instance-wide.

### Default artifacts expiration

Job artifacts expiration can be set **instance-wide** in the Admin area.

If not manually set, it defaults to 30 days.<br/>
Set the value to `0` to disable artifacts expiration. The default unit is in seconds.

Path: _Admin_ > _Settings_ > _CI/CD_ > _Continuous Integration and Deployment_ > _Default artifacts expiration_.<br/>
Syntax: [`artifacts:expire_in`](https://docs.gitlab.com/ee/ci/yaml/index.html#artifactsexpire_in).

This setting is set per-job and can be overridden in pipelines.

> Any changes to this setting applies to **new** artifacts only.<br/>
> The expiration time is **not** updated retroactively (for artifacts created **before** this setting was changed).

### Keep the latest artifacts for all jobs in the latest successful pipelines

Locks the artifacts of the **most recent successful** pipeline for each Git ref (branches and tags) against
deletion.<br/>
Those artifacts are kept **regardless** of their expiration.

This setting is enabled by default.<br/>
When disabled, the latest artifacts for any new successful or fixed pipelines are allowed to expire.

This setting **takes precedence over the project's setting**.<br/>
If disabled for the entire instance, it **will not** have effect in individual projects.

To disable the setting:

Path: _Admin_ > _Settings_ > _CI/CD_ > _Continuous Integration and Deployment_ > _Keep the latest artifacts for all jobs
in the latest successful pipelines_.

When disabling this feature, the latest artifacts do **not** immediately expire.<br/>
A new pipeline must run before the latest artifacts can expire and be deleted.

## Login via Google, Github or other services

Refer [OmniAuth].<br/>
See also [Password authentication enabled] to disable authentication via local user.

Users can sign in a GitLab server by using their credentials from Google, GitHub, and other popular services.

GitLab uses the _OmniAuth_ Rack framework to provide this kind of integration.

When configured, additional sign-in options are displayed on the sign-in page.

When configuring an OmniAuth provider, one should also configure the settings that are common for all providers.<br/>
Changes to those values will have **no** effect until the provider they reference is effectively configured.

<details style='padding: 0 0 1rem 1rem'>
  <summary>Settings of interest</summary>

| Option                     | Summary                                                                                                                                                                                                             |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `allow_single_sign_on`     | When `true`, automatically creates GitLab accounts when signing in with OmniAuth.<br/>When `false`, a GitLab account must be created first.<br/>When an array, limit for what providers to act as it if was `true`. |
| `auto_link_user`           | Automatically link existing GitLab users to an OmniAuth provider if their emails match when authenticating through the provider.<br/>Does **not** work with SAML.                                                   |
| `block_auto_created_users` | When `true`, GitLab puts automatically-created users in a pending approval state until they are approved by an administrator.<br/>In this state, users are unable to sign in.                                       |
| `enabled`                  | When `true`, enable usage of OmniAuth providers.                                                                                                                                                                    |
| `external_providers`       | Define which OmniAuth providers will **not** grant access to _internal_ GitLab projects.                                                                                                                            |
| `providers`                | What providers to enable.                                                                                                                                                                                           |

```rb
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_allow_single_sign_on'] = ['saml', 'google_oauth2']
gitlab_rails['omniauth_block_auto_created_users'] = true
gitlab_rails['omniauth_auto_link_user'] = ['google_oauth2', 'openid_connect']
gitlab_rails['omniauth_allow_bypass_two_factor'] = ['google_oauth2']
gitlab_rails['omniauth_sync_profile_from_provider'] = ['google_oauth2']
gitlab_rails['omniauth_external_providers'] = ['saml']
gitlab_rails['omniauth_providers'] = [{
  name: 'google_oauth2',
  app_id: '012345678901-abcdefghijklmnopqrstuvwxyz012345.apps.googleusercontent.com',
  app_secret: 'GOCSPX-something',
  args: { access_type: 'offline', approval_prompt: '' }
}]
```

</details>

## Troubleshooting

### Use access tokens to clone projects

```sh
git clone "https://oauth2:${ACCESS_TOKEN}@somegitlab.com/vendor/package.git"
```

### GitLab keeps answering with code 502

Refer [The docker images for gitlab-ce and gitlab-ee start workhorse with incorrect socket ownership].

Error message example:

> ==> /var/log/gitlab/nginx/gitlab_error.log <==<br/>
> 2024/05/09 20:57:57 \[crit] 617#0: *26 connect() to unix:/var/opt/gitlab/gitlab-workhorse/sockets/socket failed (13:
> Permission denied) while connecting to upstream, client: 172.21.0.1, server: gitlab.lan, request: "GET / HTTP/2.0",
> upstream: "http\://unix:/var/opt/gitlab/gitlab-workhorse/sockets/socket:/", host: "gitlab.lan:8443"

Context: GitLab 16.11.2 CE running from Docker image.

Root cause: the socket's permissions are mapped incorrectly.

Solution: set the correct ownership with
`docker exec 'gitlab' chown 'gitlab-www:git' '/var/opt/gitlab/gitlab-workhorse/sockets/socket'`.

## Further readings

- [Self-hosting]
- GitLab's helm [chart]
- GitLab's helm [chart]'s [global settings]
- [Command-line options]
- [Deployment] guide
- Install [runners on kubernetes]
- [TLS] configuration
- [Adding and removing Kubernetes clusters]
- GitLab's [operator code] and relative [guide][operator guide]
- [Buildah]
- [Kaniko]
- [The GitLab Handbook]
- [Icons]
- [Upgrade Path tool]
- [Elasticsearch]
- [CODEOWNERS syntax]
- [GitLab CLI][glab]

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
- [Forks]
- [Upgrade packaged PostgreSQL server]
- [Automate storage management]
- [CI/CD Admin area settings]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[maintenance mode]: #maintenance-mode

<!-- Knowledge base -->
[buildah]: ../buildah.md
[glab]: glab.md
[kaniko]: ../kaniko.md
[self-hosting]: ../self-hosting.md

<!-- Files -->
<!-- Upstream -->
[ability to reference maintainers or developers from codeowners]: https://gitlab.com/gitlab-org/gitlab/-/issues/282438
[adding and removing kubernetes clusters]: https://docs.gitlab.com/ee/user/project/clusters/add_remove_clusters.html
[automate storage management]: https://docs.gitlab.com/ee/user/storage_management_automation.html
[autoscaling gitlab runner on aws ec2]: https://docs.gitlab.com/runner/configuration/runner_autoscale_aws/
[back up gitlab excluding specific data from the backup]: https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html#excluding-specific-data-from-the-backup
[back up gitlab using amazon s3]: https://docs.gitlab.com/ee/administration/backup_restore/backup_gitlab.html?tab=Linux+package+%28Omnibus%29#using-amazon-s3
[caching in ci/cd]: https://docs.gitlab.com/ee/ci/caching/
[chart cpu and ram resource requirements]: https://docs.gitlab.com/charts/installation/deployment.html#cpu-and-ram-resource-requirements
[chart]: https://docs.gitlab.com/charts/
[ci/cd admin area settings]: https://docs.gitlab.com/ee/administration/settings/continuous_integration.html
[code owners]: https://docs.gitlab.com/ee/user/project/codeowners/
[codeowners syntax]: https://docs.gitlab.com/ee/user/project/codeowners/reference.html
[command-line options]: https://docs.gitlab.com/charts/installation/command-line-options.html
[deployment]: https://docs.gitlab.com/charts/installation/deployment.html
[elasticsearch]: https://docs.gitlab.com/ee/integration/advanced_search/elasticsearch.html
[environment variables]: https://docs.gitlab.com/ee/administration/environment_variables.html
[forks]: https://docs.gitlab.com/ee/user/project/repository/forking_workflow.html
[gitlab 17.8 release - use roles to define project members as code owners]: https://about.gitlab.com/releases/2025/01/16/gitlab-17-8-released/#use-roles-to-define-project-members-as-code-owners
[gitlab ha scaling runner vending machine for aws ec2 asg]: https://gitlab.com/guided-explorations/aws/gitlab-runner-autoscaling-aws-asg#gitlab-runners-on-aws-spot-best-practices
[gitlab maintenance mode]: https://docs.gitlab.com/ee/administration/maintenance_mode/
[global settings]: https://docs.gitlab.com/charts/charts/globals.html
[how to restart gitlab]: https://docs.gitlab.com/ee/administration/restart_gitlab.html
[icons]: https://gitlab-org.gitlab.io/gitlab-svgs/
[install gitlab with the linux package]: https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/doc/installation/index.md
[install self-managed gitlab]: https://about.gitlab.com/install
[merge request approval rules]: https://docs.gitlab.com/ee/user/project/merge_requests/approvals/rules.html
[minimal minikube example values file]: https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/values-minikube-minimum.yaml
[OmniAuth]: https://docs.gitlab.com/integration/omniauth/
[operator code]: https://gitlab.com/gitlab-org/cloud-native/gitlab-operator
[operator guide]: https://docs.gitlab.com/operator/
[package configuration file template]: https://gitlab.com/gitlab-org/omnibus-gitlab/-/raw/master/files/gitlab-config-template/gitlab.rb.template
[Password authentication enabled]: https://gitlab.com/help/administration/settings/sign_in_restrictions.md#password-authentication-enabled
[reset a user's password]: https://docs.gitlab.com/ee/security/reset_user_password.html
[restore gitlab]: https://docs.gitlab.com/ee/administration/backup_restore/restore_gitlab.html
[runners on kubernetes]: https://docs.gitlab.com/runner/install/kubernetes.html
[sign-up restrictions]: https://docs.gitlab.com/ee/administration/settings/sign_up_restrictions.html
[support object storage bucket prefixes]: https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3376
[the docker images for gitlab-ce and gitlab-ee start workhorse with incorrect socket ownership]: https://gitlab.com/gitlab-org/gitlab/-/issues/349846#note_1516339762
[the gitlab handbook]: https://handbook.gitlab.com/
[tls]: https://docs.gitlab.com/charts/installation/tls.html
[tutorial: use buildah in a rootless container with gitlab runner operator on openshift]: https://docs.gitlab.com/ee/ci/docker/buildah_rootless_tutorial.html
[uninstall the linux package (omnibus)]: https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/doc/installation/index.md#uninstall-the-linux-package-omnibus
[upgrade packaged postgresql server]: https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server
[upgrade path tool]: https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/
[use kaniko to build docker images]: https://docs.gitlab.com/ee/ci/docker/using_kaniko.html

<!-- Others -->
[chef infra]: https://www.chef.io/products/chef-infra
[configuring private dns zones and upstream nameservers in kubernetes]: https://kubernetes.io/blog/2017/04/configuring-private-dns-zones-upstream-nameservers-kubernetes/
[gitlab provider installation & configuration]: https://www.pulumi.com/registry/packages/gitlab/installation-configuration/
[gitlab provider's readme]: https://github.com/pulumi/pulumi-gitlab/blob/master/README.md
[how to disable the two-factor authentication in gitlab?]: https://stackoverflow.com/questions/31024771/how-to-disable-the-two-factor-authentication-in-gitlab
[how to upgrade your omnibus gitlab]: https://medium.com/kocsistem/how-to-upgrade-your-omnibus-gitlab-9179bb710ca
[using gitlab token to clone without authentication]: https://stackoverflow.com/questions/25409700/using-gitlab-token-to-clone-without-authentication#29570677
