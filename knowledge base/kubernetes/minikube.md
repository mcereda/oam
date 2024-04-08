# Minikube

1. [TL;DR](#tldr)
1. [Troubleshooting](#troubleshooting)
   1. [What happens if one uses the _LoadBalancer_ type with Services](#what-happens-if-one-uses-the-loadbalancer-type-with-services)
   1. [Use custom certificates](#use-custom-certificates)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

<details>
  <summary>Installation and configuration</summary>

```sh
# Install minikube.
sudo pacman -S 'minikube'
brew install 'docker' 'minikube'

# Shell completion.
source <(minikube completion "$(basename $SHELL)")

# Convenience alias.
alias kubectl="minikube kubectl --"
```

User configuration options are overridden by command flags.

```sh
# See defaults for individual configuration values.
minikube config defaults 'disk-size'
minikube config defaults 'container-runtime'

# Get individual user configuration values.
minikube config get 'cache'
minikube config get 'driver'
minikube config get 'kubernetes-version'

# Set individual user configuration values.
minikube config set 'cpus' '4'
minikube config set 'profile' 'awx-cluster'
minikube config set 'rootless' true

# View the current user configuration.
minikube config view

# Unset user configuration values.
minikube config unset 'memory'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# Start clusters.
minikube start
minikube -p 'profile' start --cpus '4' --memory '8192' --vm --addons 'ingress'
minikube start --driver='docker' --kubernetes-version='v1.29.0'

# Browse the addons catalog, with their current status.
minikube addons list

# Enable addons.
minikube addons enable 'dashboard'
minikube --profile 'profile' addons enable 'dashboard'

# Get IP and port of services of type NodePort.
minikube service --url 'nextcloud'
minikube service --url 'nextcloud' --namespace 'nextcloud'

# Use the equipped 'kubectl' executable.
minikube kubectl -- get pods

# Log into the minikube environment (for debugging).
minikube ssh

# Pause clusters without impacting deployed applications.
minikube pause
minikube -p 'profile' pause -A

# Unpause paused instances.
minikube unpause

# Halt clusters.
minikube stop

# Delete clusters.
minikube delete
minikube delete --all --purge
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Permanently increase the default memory limit.
# Requires the cluster to restart.
minikube config set 'memory' '16384'

# Disable new update notifications.
minikube config set 'WantUpdateNotification' false

# Disable emojis in the commands.
export MINIKUBE_IN_STYLE=false

# Create (other) clusters running specific Kubernetes versions.
minikube start -p 'old-k8s' --kubernetes-version='v1.27.1'
```

</details>

## Troubleshooting

### What happens if one uses the _LoadBalancer_ type with Services

On cloud providers that support load balancers, an external IP address would be provisioned to access the Service; on minikube, the _LoadBalancer_ type makes the Service accessible through the `minikube service` command.

### Use custom certificates

Minikibe's certificates are available in the `~/.minikube/certs` folder.

## Further readings

- [Website]
- [Drivers]
- [Kubernetes]
- [`kubectl`][kubectl]

### Sources

- [Accessing] the services
- [Getting started] guide
- Cluster [configuration]
- Minikube's [hello world]
- The [completion] command
- The [ssh] command
- Use the [docker driver]
- How to [use local docker images] in Minikube
- How to [use untrusted certs]

<!--
  References
  -->

<!-- Upstream -->
[accessing]: https://minikube.sigs.k8s.io/docs/handbook/accessing
[completion]: https://minikube.sigs.k8s.io/docs/commands/completion
[configuration]: https://minikube.sigs.k8s.io/docs/handbook/config
[docker driver]: https://minikube.sigs.k8s.io/docs/drivers/docker
[drivers]: https://minikube.sigs.k8s.io/docs/drivers
[getting started]: https://minikube.sigs.k8s.io/docs/start
[ssh]: https://minikube.sigs.k8s.io/docs/commands/ssh
[use untrusted certs]: https://minikube.sigs.k8s.io/docs/handbook/untrusted_certs
[website]: https://minikube.sigs.k8s.io

<!-- In-article sections -->
<!-- Knowledge base -->
[kubectl]: kubectl.md
[kubernetes]: README.md

<!-- Others -->
[hello world]: https://kubernetes.io/docs/tutorials/hello-minikube
[use local docker images]: https://stackoverflow.com/questions/42564058/how-to-use-local-docker-images-with-minikube#62303945
