# Multipass

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install.
brew install --cask 'multipass'
choco install 'multipass'
sudo snap install 'multipass'

# Find available VMs.
multipass find

# Launch a VM.
multipass launch --name 'primary'
multipass launch -c '2' -m '2G' -d '20G' -n 'my-test-vm' '21.10'
multipass launch 'bionic' --name 'test-cloud-init' --cloud-init 'userdata.yaml'

# List all VMs.
multipass list

# Launch a shell in the VM.
multipass shell 'vm_name'

# Stop started VMs.
multipass stop 'vm_name'

# Start stopped VMs.
multipass start 'vm_name'

# Delete stopped VMs.
multipass delete my-test-vm

# Clean up unused data.
multipass purge
```

## Further readings

- [Website]

## Sources

All the references in the [further readings] section, plus the following:

- [Use Linux Virtual Machines with Multipass]

<!--
  References
  -->

<!-- Upstream -->
[website]: https://multipass.run/

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[use linux virtual machines with multipass]: https://medium.com/codex/use-linux-virtual-machines-with-multipass-4e2b620cc6
