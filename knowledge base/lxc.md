# Linux Container Runtime

1. [TL;DR](#tldr)
1. [Create new containers as an unprivileged user](#create-new-containers-as-an-unprivileged-user)
1. [Further readings](#further-readings)

## TL;DR

<details>
  <summary>Setup</summary>

```sh
# Install the LXC runtime.
apt install 'lxc'
snap install 'lxd'

# Check the kernel's configuration allows running containers.
lxc-checkconfig

# Ensure containers can connect to the Internet.
# Especially needed when Docker is also installed.
# 1. enables forwarding; 2. nats traffic from containers; 3. allows initiating traffic from containers; 4. allows
# responses.
# 10.0.3.0/24 -> LXC bridge subnet, enp1s0 -> host network interface, lxcbr0 -> LXC bridge network interface.
# Specifying an interface (e.g., -o 'enp1s0') limits the rule to it. Leave them out to allow traffic on *all* of them.
sysctl -w 'net.ipv4.ip_forward=1' \
&& iptables -t 'nat' -A 'POSTROUTING' -s '10.0.3.0/24' ! -d '10.0.3.0/24' -o 'enp1s0' -j 'MASQUERADE' \
&& iptables -A 'FORWARD' -i 'lxcbr0' -o 'enp1s0' -j 'ACCEPT' \
&& iptables -A 'FORWARD' -i 'enp1s0' -o 'lxcbr0' -m 'conntrack' --ctstate 'RELATED,ESTABLISHED' -j 'ACCEPT'
```

</details>

<details>
  <summary>Usage</summary>

```sh
# List available templates.
ls '/usr/share/lxc/templates'

# List available base images.
# `lxc-create` requires the `--name` option for this too.
# It creates the container, but does nothing else.
lxc-create --name 'list-images' --template 'download' -- --list; lxc-destroy --name 'list-images'
lxc-create -n 'test' -t 'download' -- -l --server 'images.linuxcontainers.org'; lxc-destroy -n 'list-images'

# Create containers interactively.
# Makes one choose from a list of images.
lxc-create --name 'some-name' --template 'download'
lxc-create -n 'some-name' -t 'download'
# Create containers non-interactively.
# Values are case sensitive and depend on what is available on the server.
lxc-create --name 'alpine' --template 'download' -- --dist 'Alpine' --release '3.24' --arch 'armv7l'
lxc-create -n 'ubuntu-stonking' -t 'download' -- \
  -s 'repo.turris.cz/lxc' \
  -d 'ubuntu' -r 'stonking' -a 'armhf'

# List existing containers.
lxc-ls
lxc-ls --fancy

# Show information about existing containers
lxc-info --name 'nextcloud'
lxc-info -n 'pi-hole'
lxc-info --name 'forgejo' --ips --no-humanize

# Start containers.
lxc-start --name 'baikal'
lxc-start -n 'forgejo' --foreground
lxc-start 'cfengine' --daemon --define 'CONFIGVAR=VALUE'

# Get a shell into running containers.
lxc-attach --name 'pi-hole'
lxc-attach -n 'nextcloud' --clear-env
lxc-attach 'forgejo'

# Stop containers.
lxc-stop --name 'gitea'
lxc-stop -n 'forgejo' --kill
lxc-stop 'nextcloud'

# Delete containers and their data.
# Requires the container to be already stopped.
lxc-destroy --name 'gitea'
lxc-destroy -n 'forgejo'
lxc-destroy 'nextcloud'

# Get configuration options from `man`
man 5 'lxc.container.conf'
man 'lxc.container.conf.5'
man 'lxc.container.conf(5)'
```

</details>

<details>
  <summary>Real world use cases</summary>

```sh
# Allow user 'vagrant' to create up to 10 'veth' devices connected to the 'lxcbr0' bridge.
echo "vagrant veth lxcbr0 10" | sudo tee -a '/etc/lxc/lxc-usernet'

# Only get the first IP address of containers.
lxc-info --name 'forgejo' --ips --no-humanize | head -n '1'

# Expose container ports to the outside.
iptables -t 'nat' -A 'PREROUTING' ! -s '10.0.3.0/24' -p 'tcp' --dport '443' -j 'DNAT' --to-destination '10.0.3.42:443' \
&& iptables -A 'FORWARD' -p 'tcp' -d '10.0.3.42' --dport '443' -j 'ACCEPT'
iptables -t 'nat' -A 'PREROUTING' -i 'enp1s0' -p 'tcp' -m 'multiport' --dports '8080,8443' -j 'DNAT' \
  --to-destination '10.0.3.42' \
&& iptables -A 'FORWARD' -i 'enp1s0' -o 'lxcbr0' -p 'tcp' -d '10.0.3.42' -m 'multiport' --dports '8080,8443' -j 'ACCEPT'
```

</details>

Newly created containers usually™ come with their hostname already set to the container's name.

## Create new containers as an unprivileged user

```sh
# Allow user 'vagrant' to create up to 10 'veth' devices connected to the 'lxcbr0' bridge.
echo "vagrant veth lxcbr0 10" | sudo tee -a '/etc/lxc/lxc-usernet'
```

## Further readings

- [Website]
- [Getting started guide][getting started]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Upstream -->
[Getting started]: https://linuxcontainers.org/lxc/getting-started/
[Website]: https://linuxcontainers.org/
