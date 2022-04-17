# Linux Container Runtime

## TL;DR

```shell
# install lxc
apt-get install lxc
snap install lxd

# list available templates
ls /usr/share/lxc/templates

# create a new container
# use the download template to choose from a list of distribution
lxc-create --name container-name --template download

# start a container
lxc-start --name container-name
lxc-start --name container-name --foreground
lxc-start --name container-name --daemon --define CONFIGVAR=VALUE

# stop a container
lxc-stop --name container-name
lxc-stop --name container-name --kill

# destroy a container
# needs the container to be stopped
lxc-destroy --name container-name

# get a container status
lxc-info --name container-name

# get the status of all containers
lxc-ls --fancy

# get a shell inside a container
lxc-attach --name container-name

# get config options on man
man 5 lxc.container.conf
man lxc.container.conf.5
man lxc.container.conf(5)
```

## Create new containers as unprivileged user

```shell
# allow user vagrant to create up to 10 veth devices connected to the lxcbr0 bridge
echo "vagrant veth lxcbr0 10" | sudo tee -a /etc/lxc/lxc-usernet
```

## Further readings

- LXC's [website]
- LXC's [getting started] guide

[website]: https://linuxcontainers.org/
[getting started]: https://linuxcontainers.org/lxc/getting-started/
