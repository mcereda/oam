# Toolbox

Runs on top of [Podman].

## TL;DR

```sh
# List locally available images and containers.
toolbox list
toolbox list -c

# Download an OCI image and create a container from it.
toolbox create
toolbox create -d rhel -r 8.1
toolbox create -i registry.fedoraproject.org/fedora-toolbox:35 fedora

# Run a command inside the container without entering it.
toolbox run ls -la
toolbox run -d rhel -r 8.1 uptime
toolbox-run -c fedora cat /etc/os-release

# Get a shell inside the container.
toolbox enter
toolbox enter -d fedora -r f35
toolbox enter rhel

# Remove a container.
toolbox rm fedora-toolbox-35

# Remove an image.
toolbox rmi fedora-toolbox:35
toolbox rmi -af
```

## Further readings

- [GitHub] page
- [Podman]

[podman]: podman.md

[github]: https://github.com/containers/toolbox

## Sources

- [Fedora Silverblue]

[fedora silverblue]: https://docs.fedoraproject.org/en-US/fedora-silverblue/toolbox/
