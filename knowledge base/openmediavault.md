# OpenMediaVault

NAS solution based on [Debian Linux][debian].

1. [TL;DR](#tldr)
1. [First access](#first-access)
1. [Suggested first steps](#suggested-first-steps)
1. [Create users](#create-users)
1. [Make users OpenMediaVault administrators](#make-users-openmediavault-administrators)
1. [Disable the default `admin` user](#disable-the-default-admin-user)
1. [Configuration backup](#configuration-backup)
1. [Wake On Lan](#wake-on-lan)
1. [Power management](#power-management)
   1. [CPU governor](#cpu-governor)
   1. [Disk power options](#disk-power-options)
1. [OMV Extras](#omv-extras)
1. [Antivirus](#antivirus)
1. [UPS](#ups)
1. [ZFS](#zfs)
1. [Further readings](#further-readings)
    1. [Sources](#sources)

## TL;DR

Default web UI login is `admin`:`openmediavault`.

```sh
# Make users OMV administrators.
usermod -aG 'openmediavault-admin' 'me'
gpasswd -a 'me' 'openmediavault-admin'
adduser 'me' 'openmediavault-admin'

# Allow users to connect via SSH.
usermod -aG '_ssh' 'me'
gpasswd -a 'me' '_ssh'
adduser 'me' '_ssh'

# Revoke WebUI access from the 'admin' user.
gpasswd -d 'admin' 'openmediavault-admin'
deluser 'admin' 'openmediavault-admin'

# Install plugins from the CLI.
apt install 'openmediavault-clamav' … 'openmediavault-nut'

# Install OMV-Extras.
wget -O - 'https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install' | bash

# Use ZFS.
# Requires OMV-Extras.
apt install 'openmediavault-kernel'
# Install the Proxmox kernel and reboot
apt install 'openmediavault-zfs'
zpool import -a

# Upgrade packages.
sudo omv-upgrade

# Move to the next release.
# Includes upgrading the OS to the next version.
# E.g.: Debian 11 -> 12 + OMV 6 -> 7
tmux new-session -As 'omv-release-upgrade' "sudo omv-release-upgrade"
```

Backup the current OMV configuration by backing up the `/etc/openmediavault/config.xml` file.

## First access

The SSH and web UI servers are active by default on port 22 and 80 respectively.

The default web UI administrator login is `admin`:`openmediavault`.<br/>
This user **cannot** login locally, **nor** connect via SSH by default. It only can access OMV's web UI.

The `root` user's password is set during OS installation.<br/>
This user **can** connect via SSH by default.

## Suggested first steps

1. [Create a custom user][create users].<br/>
   Make the new custom user a system administrator to avoid using `root` for normal usage.
1. [Make the new custom user an OpenMediaVault administrator][make users openmediavault administrators].
1. Change the `admin` user's password and [disable it][disable the default admin user].
1. Disable SSH access for the `root` user in _Services_ > _SSH_.

## Create users

Just do it as for any other GNU/Linux system:

```sh
useradd -mG 'users' 'me' && passwd 'me'
adduser 'me' && adduser 'me' 'users'
```

If the user needs administrator privileges, consider adding it to the `sudo` group:

```sh
usermod -aG 'sudo' 'me'
gpasswd -a 'me' 'sudo'
adduser 'me' 'sudo'
```

## Make users OpenMediaVault administrators

Just add the users to the `openmediavault-admin` group:

```sh
usermod -aG 'openmediavault-admin' 'me'
gpasswd -a 'me' 'openmediavault-admin'
adduser 'me' 'openmediavault-admin'
```

## Disable the default `admin` user

Only do this **after** you created another user and [made it an OMV admin][make users openmediavault administrators].

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
   deluser --remove-home 'admin'
   ```

## Configuration backup

OMV's whole configuration is saved in the `/etc/openmediavault/config.xml` file.<br/>
Keep a backup of it somewhere **outside** the host running it.

Alternatively, consider using [omv-regen] as suggested in
[this thread][migrate/restore omv settings to another system with omv-regen].

## Wake On Lan

The network interface **must** support this feature and it **must** be enabled in the BIOS.

WOL is **not** enabled by default in the kernel driver.<br/>
Enable the option under _Network_ > _Interfaces_, in **every** NIC's settings you want to respond.

## Power management

```sh
sudo apt install 'powertop'
sudo powertop --auto-tune
sudo powertop --calibrate
```

### CPU governor

Enabling the _Monitoring_ option under _System_ > _Power Management_ configures `cpufrequtils`.<br/>
For x86 architectures, this also sets the default governor to `conservative`. If the architecture is different, the
governor is set to `ondemand`.

### Disk power options

By default disks have no power management configured.

Editing a disk under _Storage_ > _Disks_ will allow to set these options for it:

- Advanced power management.
- Automatic acoustic management.<br/>
  Not all drives support this.
- Spin down time.
- Write cache.

All the above options are configured using [`hdparm`][hdparm].

The APM values from the interface are resumed in seven steps.<br/>
To experiment with intermediate values:

- Edit `/etc/openmediavault/config.xml`.
- Find the `/storage/hdparm` xpath.
- Change the values for the disk.
- Run this command:

  ```sh
  omv-salt deploy run hdparm
  ```

- Reboot.
- Check if APM has been set:

  ```sh
  hdparm -I "/dev/sdX"
  ```

When setting a spin down time, make sure the APM value is set lower than `128`. It will not work otherwise.<br/>
The web framework does not narrow the APM options if the spin down time is set, nor it disables the spin down option
when a value higher than 128 is selected for APM.

## OMV Extras

From the CLI, as the `root` user:

1. Install [OMV-Extras]:

   ```sh
   wget -O - \
     'https://github.com/OpenMediaVault-Plugin-Developers/packages/raw/master/install' \
   | bash
   ```

## Antivirus

1. Install the `openmediavault-clamav` plugin.
1. Enable the service under _Services_ > _Antivirus_ > _Settings_.
1. Apply pending changes.<br/>
   The first run will take a long time.

## UPS

1. Install the `openmediavault-nut` plugin.
1. Enable the service under _Services_ > _UPS_.
1. Apply pending changes.

## ZFS

1. [Install OMV-Extras][omv extras].
1. Pick one:

   - \[preferred] Install the `openmediavault-kernel` plugin and use it to install the Proxmox kernel.

     Debian does **not** build ZFS kernel modules into any of their kernels due to licensing conflicts, and doing it
     manually may result in an extensive build process during installation, which is prone to errors.<br/>
     The Proxmox-Debian kernel has the ZFS kernel modules preinstalled by default. As kernel upgrades become available
     and are performed, the userland for the Proxmox kernel will always have the required packages to support ZFS.

   - Disable the kernel's backports APT sources and stick to the mainline one.

     > [!warning]
     > Linux backport kernels are released quickly enough to leave the userland incomplete at times. This happens often
     > with ZFS, resulting in broken package issues.

     ```sh
     mv -v \
       '/etc/apt/sources.list.d/openmediavault-kernel-backports.list' \
       '/etc/apt/sources.list.d/openmediavault-kernel-backports.list.disabled'
     ```

1. Install the `openmediavault-zfs` plugin.
1. Create new pools, or import existing ones.

   > [!note]
   > One might need to wipe the disks before creating new pools.

ZFS does provide ACL support, but it is **not** enabled by default.<br/>
Just enable that property in the pool or datasets.

## Further readings

- [Website]
- [Documentation]
- [Debian]
- [Proxmox]
- [OMV-Extras]
- [Disks maintenance]
- [ZFS]

### Sources

- [How to lock or disable an user account]
- [ZFS plugin for OMV6]
- [Software & Update Management]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
[Create users]: #create-users
[Disable the default admin user]: #disable-the-default-admin-user
[Make users OpenMediaVault administrators]: #make-users-openmediavault-administrators
[omv extras]: #omv-extras

<!-- Knowledge base -->
[debian]: linux/debian.md
[disks maintenance]: disks%20maintenance.md
[proxmox]: proxmox.md
[zfs]: zfs.md

<!-- Upstream -->
[documentation]: https://docs.openmediavault.org/en/latest/
[Migrate/Restore OMV Settings to Another System with omv-regen]: https://forum.openmediavault.org/index.php?thread/47589-how-to-migrate-restore-omv-settings-to-another-system-with-omv-regen/
[omv-extras]: https://wiki.omv-extras.org/
[software & update management]: https://docs.openmediavault.org/en/stable/various/apt.html
[website]: https://www.openmediavault.org/
[zfs plugin for omv6]: https://wiki.omv-extras.org/doku.php?id=docs_in_draft:zfs

<!-- Others -->
[hdparm]: https://linux.die.net/man/8/hdparm
[how to lock or disable an user account]: https://www.thegeekdiary.com/unix-linux-how-to-lock-or-disable-an-user-account/
[omv-regen]: https://github.com/xhente/omv-regen
