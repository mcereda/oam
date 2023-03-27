# ZFS

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Gotchas](#gotchas)
1. [Manjaro](#manjaro)
1. [Raspberry Pi](#raspberry-pi)
1. [Mac OS X](#mac-os-x)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

Pool-related:

```sh
# Create pools on single devices.
zpool create 'pool_name' 'path_to_device'

# Create encrypted pools using multiple devices.
zpool create \
  -o 'feature@encryption=enabled' \
  -O 'encryption=on' -O 'keyformat=passphrase' \
  'pool_name' \
  '/dev/sdb' '/dev/sdc' '/dev/sdd'

# List available pools.
zpool list

# Show pools configuration and status.
zpool status
zpool status 'pool_name' 'time_in_seconds'

# Show pools i/o statistics.
zpool iostat
zpool iostat 'pool_name' -n '1'

# Check a pool for errors.
# Verifies the checksum of every block.
# Very cpu and disk intensive.
zpool scrub 'pool_name'

# List all pools available for import.
zpool import

# Import pools.
zpool import 'pool_name'
zpool import 'pool_name' -N
zpool import 'encrypted_pool_name' -l

# Export pools.
# Unmounts all filesystems in the pool.
zpool export 'pool_name'

# Show the history of all pool's operations.
zpool history 'pool_name'

# Create mirrored pools.
zpool create 'pool_name' mirror 'device1' 'device2' mirror 'device3' 'device4'

# Add cache (L2ARC) devices to pools.
zpool add 'pool_name' cache 'cache_disk'

# Show the current version of a pool.
zpool upgrade -v

# Upgrade pools.
zpool upgrade 'pool_name'
zpool upgrade -a

# Get pools' properties.
zpool get all 'pool_name'

# Set pools' properties.
zpool set 'compression=lz4' 'pool_name'

# Add vdevs to mirrored pools.
zpool attach 'pool_name' 'first_drive_in_existing_mirror' 'new_dev'

# Destroy pools.
zpool destroy 'pool_name'

# Restore a destroyed pool.
# The pool needs to be reimported straight after the destroy command has been
# issued.
zpool import -D

# Get info about zpools features.
man zpool-features
```

Filesystem-related:

```sh
# List all available datasets (filesystems).
zfs list

# Automatically mount or unmount filesystems.
# See 'zfs get mountpoint pool_name' for a dataset's mountpoint's root path.
zfs mount -alv
zfs unmount 'pool_name/filesystem_name'

# Create new filesystems.
zfs create 'pool_name/filesystem_name'

# Delete filesystems.
zfs destroy 'pool_name/filesystem_name'

# List all snapshots.
zfs list -t 'snapshot'

# Recursively list snapshots for a given dataset, outputting only name and
# creation date
zfs list -r -t 'snapshot' -o 'name,creation' 'pool_name/filesystem_name'

# Create new snapshots.
zfs snapshot 'pool_name/filesystem_name@snapshot_name'

# Destroy snapshots.
zfs destroy  'pool_name/filesystem_name@snapshot_name'

# Query a file system or volume configuration (get properties).
zfs get all 'pool_name'
zfs get all 'pool_name/filesystem_name'

# Enable or change settings on a filesystem.
zfs set 'compression=on' 'pool_name/filesystem_name'
zfs set 'mountpoint=/my/mount/path' 'pool_name/filesystem_name'

# Get more information about zfs volumes properties.
man zfs
```

Procedure examples:

```sh
# Create a dataset in a new pool, adjust its permissions and unmount the pool.
sudo zpool create \
  -o 'feature@encryption=enabled' \
  -O 'encryption=on' -O 'keyformat=passphrase' \
  'vault' '/dev/sdb'
sudo zfs create 'vault/data'
sudo chown "$USER":'users' '/vault/data'
sudo zpool export 'vault'
```

## Gotchas

- One **cannot shrink** an existing pool.
- One **cannot remove vdevs** after a pool is created.
- More than 9 drives in one RAIDZ can cause performance regression; use 2 RAIDZ with 5 drives each instead of 1 RAIDZ with 10 drives to avoid this.
- One can **add** hot spares to a RAIDZ1 or RAIDZ2 pool.
- One can replace a drive with a bigger one (but **not a smaller one**) one at a time.
- One can mix MIRROR, RAIDZ1 and RAIDZ2 in a pool.
- Datasets needs the mountpoint to be an **empty** folder to be mounted, unless explicitly mounted with the -O option of `zfs mount`.
- Since the ZFS kernel modules are upgraded much less than the kernel (at least on Linux), **always make sure** the kernel version and the ZFS modules are compatible and upgraded together.

## Manjaro

Manjaro has prebuilt modules for ZFS, which package is the kernel's package postfixed by `-zfs` (e.g. for `linux-515` it is `linux515-zfs`)

```sh
# Install the modules' packages for all installed kernels.
sudo pamac install $(mhwd-kernel --listinstalled | grep '*' | awk -F '* ' '{print $2}' | xargs -I {} echo {}-zfs)
```

## Raspberry Pi

The `zfs-dkms` package cannot handle downloading and installing the Raspberry Pi kernel headers automatically, so they have to be installed prior of the ZFS-related packages:

```sh
sudo apt install --upgrade 'raspberrypi-kernel' 'raspberrypi-kernel-headers'
sudo reboot
sudo apt install 'zfs-dkms' 'zfsutils-linux'
```

To be tested: If the running kernel has no updates, the packages installation might be performed together.

## Mac OS X

```sh
# On M1 devices, this requires system extensions to be enabled in the Startup
# Security Utility.
brew install --cask 'openzfs'
```

Pool options (`-o option`):

* `ashift=XX`
  * XX=9 for 512B sectors, XX=12 for 4KB sectors, XX=16 for 8KB sectors
  * [reference](http://open-zfs.org/wiki/Performance_tuning#Alignment_Shift_.28ashift.29)
* `version=28`
  * compatibility with ZFS on Linux

Filesystem options (`-O option`):

* `atime=off`
* `compression=on`
  * activates compression with the default algorithm
  * pool version 28 cannot use lz4
* `copies=2`
  * number of copies of data stored for the dataset
* `dedup=on`
  * deduplication
  * halves write speed
  * [reference](http://open-zfs.org/wiki/Performance_tuning#Deduplication)
* `xattr=sa`

```sh
sudo zpool \
  create \
    -f \
    -o comment='LaCie Rugged USB-C 4T' \
    -o version=28 \
    -O casesensitivity='mixed' \
    -O compression='on' \
    -O com.apple.mimic_hfs='on' \
    -O copies=2 \
    -O logbias='throughput' \
    -O normalization='formD' \
    -O xattr='sa' \
    'volume_name' \
    'disk2'
sudo zpool import -a
```

```sh
sudo zpool \
  create \
    -f \
    -o ashift=12 \
    -o 'feature@allocation_classes=disabled' \
    -o 'feature@async_destroy=enabled' \
    -o 'feature@bookmarks=enabled' \
    -o 'feature@device_removal=enabled' \
    -o 'feature@embedded_data=enabled' \
    -o 'feature@empty_bpobj=enabled' \
    -o 'feature@enabled_txg=enabled' \
    -o 'feature@encryption=disabled' \
    -o 'feature@extensible_dataset=enabled' \
    -o 'feature@hole_birth=enabled' \
    -o 'feature@large_dnode=disabled' \
    -o 'feature@obsolete_counts=enabled' \
    -o 'feature@spacemap_histogram=enabled' \
    -o 'feature@spacemap_v2=enabled' \
    -o 'feature@zpool_checkpoint=enabled' \
    -o 'feature@filesystem_limits=enabled' \
    -o 'feature@multi_vdev_crash_dump=enabled' \
    -o 'feature@lz4_compress=enabled' \
    -o 'feature@project_quota=disabled' \
    -o 'feature@resilver_defer=disabled' \
    -o 'feature@sha512=enabled' \
    -o 'feature@skein=enabled' \
    -o 'feature@userobj_accounting=disabled' \
    -O 'atime=off' \
    -O 'relatime=on' \
    -O 'compression=lz4' \
    -O 'logbias=throughput' \
    -O 'normalization=formD' \
    -O 'xattr=sa' \
    'volume_name' \
    '/dev/sdb'
```

## Further readings

- [OpenZFS docs]
- [Oracle Solaris ZFS Administration Guide]
- [Gentoo Wiki]
- [Archlinux Wiki]

## Sources

All the references in the [further readings] section, plus the following:

- [Article on ZFS on Linux]
- [cheat.sh/zfs]
- [Creating fully encrypted ZFS pool]
- [Aaron Toponce's article on ZFS administration]
- [How to Enable ZFS Deduplication]
- [ZFS support + kernel, best approach]

<!-- project's references -->

[openzfs docs]: https://openzfs.github.io/openzfs-docs/
[oracle solaris zfs administration guide]: https://docs.oracle.com/cd/E19253-01/819-5461/index.html

<!-- internal references -->

[further readings]: #further-readings

<!-- external references -->

[aaron toponce's article on zfs administration]: https://pthree.org/2012/12/04/zfs-administration-part-i-vdevs/
[archlinux wiki]: https://wiki.archlinux.org/title/ZFS
[article on zfs on linux]: https://blog.heckel.io/2017/01/08/zfs-encryption-openzfs-zfs-on-linux
[cheat.sh/zfs]: https://cheat.sh/zfs
[creating fully encrypted zfs pool]: https://timor.site/2021/11/creating-fully-encrypted-zfs-pool/
[gentoo wiki]: https://wiki.gentoo.org/wiki/ZFS
[how to enable zfs deduplication]: https://linuxhint.com/zfs-deduplication/
[zfs support + kernel, best approach]: https://forum.manjaro.org/t/zfs-support-kernel-best-approach/33329/2
