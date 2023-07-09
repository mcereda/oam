# UBports

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Connect using SSH](#connect-using-ssh)
1. [Sources](#sources)

## TL;DR

```sh
# List containers.
libertine-container-manager list

# Create containers.
# Default type: 'chroot'.
libertine-container-manager create -i 'identifier'
libertine-container-manager create -i 'identifier' -n 'name' -t 'lxc'

# Search for packages.
libertine-container-manager search-cache -s 'pattern'

# Install packages.
libertine-container-manager install-package -p 'package'

# Execute commands.
libertine-container-manager exec -c 'command'
libertine-launch -i 'identifier' ls -a
DISPLAY= libertine-launch ls -a

# Get a shell inside the container.
DISPLAY= libertine-launch '/bin/bash'

# Launch graphical applications from the terminal.
ubuntu-app-launch 'containerId_app_0.0'

# Remove packages.
libertine-container-manager remove-package -p 'package'

# Destroy containers.
libertine-container-manager destroy -i 'identifier'
```

## Connect using SSH

> SSH is configured to allow only public key-based access.

1. Open the terminal application.
1. Download, receive or otherwise write the public key on your device:

   ```sh
   wget 'https://some.reachable.url/key.pub'
   ```

1. Copy the key to the `authorized_keys` file; start from the following commands:

   ```sh
   mkdir "${HOME}/.ssh"
   chmod 700 "${HOME}/.ssh"
   cat "${HOME}/key.pub" >> "${HOME}/.ssh/authorized_keys"
   chmod 600 "${HOME}/.ssh/authorized_keys"
   ```

1. Start SSH:

   ```sh
   # On Android-based devices (like the OnePlus One).
   sudo android-gadget-service enable ssh

   # On Linux-based devices (like the PinePhone).
   sudo service ssh start
   ```

1. Optionally, find the device's IP address:

   ```sh
   hostname -I
   ```

1. Finally, connect from a device using the private key and the `phablet` user:

   ```sh
   ssh -i 'path/to/private.key' 'phablet@ubuntu-phablet.lan'
   ```

## Sources

- [Documentation]

<!--
  References
  -->

<!-- Upstream -->
[documentation]: https://docs.ubports.com/en/latest/index.html
