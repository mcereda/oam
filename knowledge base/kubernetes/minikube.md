# Minikube

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Troubleshooting](#troubleshooting)
   1. [What happens if I use the _LoadBalancer_ type with Services?](#what-happens-if-i-use-the-loadbalancer-type-with-services)
   1. [Can I use custom certificates?](#can-i-use-custom-certificates)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install minikube.
sudo pacman -S 'minikube'
brew install 'docker' 'minikube'

# Shell completion.
source <(minikube completion "$(basename $SHELL)")

# Disable emojis in the commands.
export MINIKUBE_IN_STYLE=false

# Start the cluster.
minikube start
minikube start --cpus '4' --memory '8192'

# Pause the cluster without impacting deployed applications
minikube pause

# Halt the cluster.
minikube stop

# Permanently increase the default memory limit.
# Requires the cluster to restart.
minikube config set 'memory' '16384'

# Browse the catalog of easily installable Kubernetes services.
minikube addons list

# Create a(nother) cluster running a specific Kubernetes version.
minikube start -p 'old-k8s' --kubernetes-version='v1.16.1'
minikube config set 'kubernetes-version' 'v1.16.15' && minikube start

# Use a specific docker driver.
minikube start --driver='docker'
minikube config set 'driver' 'docker' && minikube start

# Disable new update notifications.
minikube config set 'WantUpdateNotification' false

# Get IP and port of a service of type NodePort.
minikube service --url 'nextcloud'
minikube service --url 'nextcloud' --namespace 'nextcloud'

# Use the integrated kubectl command.
minikube kubectl -- get pods

# Log into the minikube environment (for debugging).
minikube ssh

# Delete all the clusters.
minikube delete --all --purge
```

## Troubleshooting

### What happens if I use the _LoadBalancer_ type with Services?

On cloud providers that support load balancers, an external IP address would be provisioned to access the Service; on minikube, the _LoadBalancer_ type makes the Service accessible through the `minikube service` command.

### Can I use custom certificates?

Minikibe's certificates are available in the `~/.minikube/certs` folder.

## Further readings

- [Website]
- [Drivers]
- [Kubernetes]
- [`kubectl`][kubectl]

## Sources

All the references in the [further readings] section, plus the following:

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
[further readings]: #further-readings

<!-- Knowledge base -->
[kubectl]: kubectl.md
[kubernetes]: README.md

<!-- Others -->
[hello world]: https://kubernetes.io/docs/tutorials/hello-minikube
[use local docker images]: https://stackoverflow.com/questions/42564058/how-to-use-local-docker-images-with-minikube#62303945
