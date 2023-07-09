# Linux Container Runtime

## TL;DR

```sh
# Install the LXC runtime
apt-get install 'lxc'
snap install 'lxd'

# List available templates.
ls '/usr/share/lxc/templates'

# Create new containers.
# Use the 'download' template to choose from a list of distribution
lxc-create -n 'pi-hole' --template 'download'

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

## Sources

All the references in the [further readings] section, plus the following:

<!-- upstream -->
[getting started]: https://linuxcontainers.org/lxc/getting-started/
[website]: https://linuxcontainers.org/

<!-- internal references -->
[further readings]: #further-readings

<!-- external references -->
