# OpenMediaVault

NAS solution based on [Debian Linux][debian].

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Make other users administrators](#make-other-users-administrators)
1. [Remove access for the default admin user](#remove-access-for-the-default-admin-user)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install OMV-Extras.
wget -O - 'https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install' | bash
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

## Further readings

- [Website]
- [Debian]
- [Proxmox]
- [OMV-Extras]
- [Disks maintenance]

## Sources

All the references in the [further readings] section, plus the following:

- [How to lock or disable an user account]

<!--
  References
  -->

<!-- Upstream -->
[omv-extras]: https://wiki.omv-extras.org/
[website]: https://www.openmediavault.org/

<!-- In-article sections -->
[further readings]: #further-readings
[make other users administrators]: #make-other-users-administrators

<!-- Knowledge base -->
[debian]: debian.md
[disks maintenance]: disks%20maintenance.md
[proxmox]: proxmox.md

<!-- Others -->
[how to lock or disable an user account]: https://www.thegeekdiary.com/unix-linux-how-to-lock-or-disable-an-user-account/
