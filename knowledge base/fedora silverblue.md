# Fedora Silverblue

## TL;DR

Changes to the base layer are executed in a new bootable filesystem root. This means that the system must be rebooted after a package has been layered.

```shell
# Check for available upgrades.
rpm-ostree upgrade --check

# Upgrade the system.
rpm-ostree upgrade

# Install packages.
rpm-ostree install kmod-nvidia xorg-x11-drv-nvidia

# Override packages.
rpm-ostree override replace \
  local/path/to/podman-3.1.2-1.fc34.x86_64.rpm \
  https://kojipkgs.fedoraproject.org/packages/podman/3.1.2/1.fc34/x86_64/podman-plugins-3.1.2-1.fc34.x86_64.rpm

# Remove packages.
# Packages will still exist in the undelying base layer, but will not appear
# in the booted root.
rpm-ostree override remove nano

# Rollback.
rpm-ostree rollback

# Make changes to the kernel's boot arguments.
rpm-ostree kargs \
  --append=rd.driver.blacklist=nouveau \
  --append=modprobe.blacklist=nouveau \
  --append=nvidia-drm.modeset=1

# Preview changes on the current filesystem.
rpm-ostree ex apply-live
```

## Package layering

Package layering works by modifying your Silverblue installation by extending the packages from which Silverblue is composed.

Using package layering creates a new _deployment_, or bootable filesystem root which **does not** affect your current root. This means that the system must be rebooted after a package has been layered.

If you don't want to reboot your system to switch to the new deployment, you can use `rpm-ostree ex apply-live` to update the current filesystem and be able to see the changes from the new deployment. It's generally expected that you use package layering sparingly, and use [flatpak]s and [toolbox].

## Further readings

- [User guide]
- [Flatpak]
- [Toolbox]

[flatpak]: flatpak.md
[toolbox]: toolbox.md

[user guide]: https://docs.fedoraproject.org/en-US/fedora-silverblue/
