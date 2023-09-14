# OpenMediaVault

NAS solution based on [Debian Linux][debian].

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Make other users administrators](#make-other-users-administrators)
1. [Remove access for the default admin user](#remove-access-for-the-default-admin-user)
1. [OMV-Extras](#omv-extras)
1. [ZFS](#zfs)
   1. [ZFS plugin](#zfs-plugin)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Make other users administrators.
gpasswd -a 'me' 'openmediavault-admin'
usermod -aG 'openmediavault-admin' 'me'

# Revoke WebUI access from the 'admin' user.
gpasswd -d 'admin' 'openmediavault-admin'
deluser 'admin' 'openmediavault-admin'

# Install plugins from the CLI.
apt install 'openmediavault-clamav'

# Install OMV-Extras.
wget -O - 'https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install' | bash

# Disable the kernel's backports sources.
mv -v \
  '/etc/apt/sources.list.d/openmediavault-kernel-backports.list' \
  '/etc/apt/sources.list.d/openmediavault-kernel-backports.list.disabled'
```

## Make other users administrators

Just add the user to the `openmediavault-admin` group:

```sh
gpasswd -a 'me' 'openmediavault-admin'
usermod -aG 'openmediavault-admin' 'me'
```

## Remove access for the default admin user

Only do this **after** you created another user and [made it an admin][make other users administrators].

From the safest to the less safe option:

1. Lock the account:
   ```sh
   chage -E0 'admin'
   ```
1. Remove it from the `openmediavault-admin` group:
   ```sh
   gpasswd -d 'admin' 'openmediavault-admin'
   deluser 'admin' 'openmediavault-admin'
   ```
1. Delete it completely:
   ```sh
   userdel -r 'admin'
   deluser 'admin'
   ```

## OMV-Extras

From the CLI, as the `root` user:

1. Install [OMV-Extras]:

   ```sh
   wget -O - \
     'https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install' \
   | bash
   ```

## ZFS

### ZFS plugin

1. [Install OMV-Extras].
1. Pick one:

   - Disable the kernel's backports APT sources and stick to the mainline one.<br/>
     Linux backport kernels are released quickly enough to leave the userland incomplete at times. This often happens with ZFS, resulting in broken package issues.

     ```sh
     mv -v \
       '/etc/apt/sources.list.d/openmediavault-kernel-backports.list' \
       '/etc/apt/sources.list.d/openmediavault-kernel-backports.list.disabled'
     ```

   - Install the `openmediavault-kernel` plugin and use it to install the Proxmox kernel.<br/>
     Debian does not build ZFS kernel modules into any of their kernels by default due to licensing conflicts. This may result in an extensive build process during installation, which is prone to errors.

     The Proxmox-Debian kernel has the ZFS kernel modules preinstalled by default. As kernel upgrades become available and are performed, the userland for the Proxmox kernel will always have the required packages to support ZFS.

1. Install the `openmediavault-zfs` plugin.
1. Create pools and such.<br/>
   You might need to wipe the disks first.

## Further readings

- [Website]
- [Debian]
- [Proxmox]
- [OMV-Extras]
- [Disks maintenance]

## Sources

All the references in the [further readings] section, plus the following:

- [How to lock or disable an user account]
- [ZFS plugin for OMV6]

<!--
  References
  -->

<!-- Upstream -->
[omv-extras]: https://wiki.omv-extras.org/
[website]: https://www.openmediavault.org/
[zfs plugin for omv6]: https://wiki.omv-extras.org/doku.php?id=docs_in_draft:zfs

<!-- In-article sections -->
[further readings]: #further-readings
[make other users administrators]: #make-other-users-administrators
[omv-extras]: #omv-extras

<!-- Knowledge base -->
[debian]: debian.md
[disks maintenance]: disks%20maintenance.md
[proxmox]: proxmox.md

<!-- Others -->
[how to lock or disable an user account]: https://www.thegeekdiary.com/unix-linux-how-to-lock-or-disable-an-user-account/
