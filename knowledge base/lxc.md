# Linux Container Runtime

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Create new containers as an unprivileged user](#create-new-containers-as-an-unprivileged-user)
1. [Further readings](#further-readings)

## TL;DR

```sh
# Install the LXC runtime
apt-get install 'lxc'
snap install 'lxd'

# List available templates.
ls '/usr/share/lxc/templates'

# List the options supported by templates.
lxc-create -t 'download' -h

# Create containers.
# Use the 'download' template to choose from a list of distribution.
lxc-create -n 'nas' -t 'download'
lxc-create --name 'nas' --template 'download' -- \
  --server 'images.linuxcontainers.org'

# Create containers non-interactively.
# Values are case sensitive and depend from what is on the server.
lxc-create -n 'alpine' -t 'download' -- -d 'Alpine' -r '3.18' -a 'armv7l'
lxc-create --name 'pi-hole' --template 'download' -- \
  --server 'repo.turris.cz/lxc' \
  --dist 'Ubuntu' --release 'Focal' --arch 'armv7l'
lxc-create … -t 'download' -- -d 'debian' -r 'bookworm' -a 'amd64' \
  --server 'images.linuxcontainers.org'

# Start containers.
lxc-start -n 'pi-hole'
lxc-start -n 'git-server' --foreground
lxc-start -n 'cfengine' --daemon --define 'CONFIGVAR=VALUE'

# Stop containers.
lxc-stop -n 'mariadb'
lxc-stop -n 'netcat' --kill

# Destroy containers.
# Requires the container to be already stopped.
lxc-destroy -n 'netcat'

# Get containers' status.
lxc-info -n 'pi-hole'

# Get the status of all containers.
lxc-ls --fancy

# Get a shell inside containers.
lxc-attach -n 'git-server'

# Get configuration options from `man`
man 5 'lxc.container.conf'
man 'lxc.container.conf.5'
man 'lxc.container.conf(5)'
```

## Create new containers as an unprivileged user

```sh
# Allow user 'vagrant' to create up to 10 'veth' devices connected to the
# 'lxcbr0' bridge.
echo "vagrant veth lxcbr0 10" | sudo tee -a '/etc/lxc/lxc-usernet'
```

## Further readings

- [Website]
- [Getting started guide][getting started]

<!--
  References
  -->

<!-- Upstream -->
[getting started]: https://linuxcontainers.org/lxc/getting-started/
[website]: https://linuxcontainers.org/
