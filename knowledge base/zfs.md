# ZFS

## TL;DR

```sh
# create a single device pool
zpool create pool_name device

# list pools
zpool list

# show pools configuration and status
zpool status
zpool status pool_name time_in_seconds

# show pools i/o statistics
zpool iostat
zpool iostat pool_name -n 1

# check a pool for errors
# verifies the checksum of every block
# very cpu and disk intensive
zpool scrub pool_name

# list all pools available for import
zpool import

# import a pool
zpool import pool_name
zpool import encrypted_pool_name -l

# export a pool
# unmounts all filesystems
zpool export pool_name

# show the history of all pool operations
zpool history pool_name

# create a mirrored pool
zpool create pool_name mirror device1 device2 mirror device3 device4

# add a cache (L2ARC) device to a pool
zpool add pool_name cache cache_disk

# show the current version of a pool
zpool upgrade -v

# upgrade pools
zpool upgrade pool_name
zpool upgrade -a

# get a pool's properties
zpool get all pool_name

# add a vdev to a mirrored pool
zpool attach pool_name first_drive_in_existing_mirror new_dev

# destroy a pool
zpool destroy pool_name

# restore a destroyed pool
# the pool needs to be reimported straight after the destroy command has been issued
zpool import -D

# get info about zpools features
man zpool-features

# list all available filesystems
zfs list

# mount or unmount filesystems
# see 'zfs get mountpoint pool_name' for mountpoint's root path
zfs mount -alv
zfs unmount pool_name/filesystem_name

# create a new filesystem
zfs create pool_name/filesystem_name

# delete a filesystem
zfs destroy pool_name/filesystem_name

# manage a snapshot
zfs list -t snapshot                                                 # list all
zfs list -r -t snapshot -o name,creation pool_name/filesystem_name   # list recursively for a given volume, output only name and creation date
zfs snapshot pool_name/filesystem_name@snapshot_name                 # create
zfs destroy  pool_name/filesystem_name@snapshot_name                 # destroy

# query a file system or volume configuration (get properties)
zfs get all pool_name
zfs get all pool_name/filesystem_name

# enable compression on a filesystem
zfs set compression=on pool_name/filesystem_name

# change mountpoint for a filesystem
zfs set mountpoint=/my/mount/path pool_name/filesystem_name

# get info about zfs volumes properties
man zfs
```

## Gotchas

- one **cannot shrink** a pool
- one **cannot remove vdevs** after a pool is created
- more than 9 drives in one RAIDZ can cause performance regression; use 2 RAIDZ with 5 drives each instead of 1 RAIDZ with 10 drives to avoid this
- one can **add** hot spares to a RAIDZ1 or RAIDZ2 pool
- one can replace a drive with a bigger one (but **not a smaller one**) one at a time
- one can mix MIRROR, RAIDZ1 and RAIDZ2 in a pool
- volumes need an **empty** folder to be mounted

## Manjaro

Manjaro has prebuilt modules for ZFS, which package is the kernel's package postfixed by `-zfs` (e.g. for `linux-515` it is `linux515-zfs`)

```sh
# install the modules' packages for all installed kernels
sudo pamac install $(mhwd-kernel --listinstalled | grep '*' | awk -F '* ' '{print $2}' | xargs -I {} echo {}-zfs)
```

## Mac OS X

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
    -O casesensitivity=mixed \
    -O compression=on \
    -O com.apple.mimic_hfs=on \
    -O copies=2 \
    -O logbias=throughput \
    -O normalization=formD \
    -O xattr=sa \
    volume_name \
    disk2
sudo zpool import -a
```

```sh
sudo zpool \
  create \
    -f \
    -o ashift=12 \
    -o feature@allocation_classes=disabled \
    -o feature@async_destroy=enabled \
    -o feature@bookmarks=enabled \
    -o feature@device_removal=enabled \
    -o feature@embedded_data=enabled \
    -o feature@empty_bpobj=enabled \
    -o feature@enabled_txg=enabled \
    -o feature@encryption=disabled \
    -o feature@extensible_dataset=enabled \
    -o feature@hole_birth=enabled \
    -o feature@large_dnode=disabled \
    -o feature@obsolete_counts=enabled \
    -o feature@spacemap_histogram=enabled \
    -o feature@spacemap_v2=enabled \
    -o feature@zpool_checkpoint=enabled \
    -o feature@filesystem_limits=enabled \
    -o feature@multi_vdev_crash_dump=enabled \
    -o feature@lz4_compress=enabled \
    -o feature@project_quota=disabled \
    -o feature@resilver_defer=disabled \
    -o feature@sha512=enabled \
    -o feature@skein=enabled \
    -o feature@userobj_accounting=disabled \
    -O atime=off \
    -O relatime=on \
    -O compression=lz4 \
    -O logbias=throughput \
    -O normalization=formD \
    -O xattr=sa \
    volume_name \
    /dev/sdb
```

## Further readings

- [ZFS support + kernel, best approach]
- [cheat.sh/zfs]
- [Oracle Solaris ZFS Administration Guide]
- [How to Enable ZFS Deduplication]
- [gentoo wiki]
- [aaron toponce's article on zfs administration]
- [archlinux wiki]
- [article on zfs on linux]

[aaron toponce's article on zfs administration]: https://pthree.org/2012/12/04/zfs-administration-part-i-vdevs/
[archlinux wiki]: https://wiki.archlinux.org/index.php/ZFS
[article on zfs on linux]: https://blog.heckel.io/2017/01/08/zfs-encryption-openzfs-zfs-on-linux
[cheat.sh/zfs]: https://cheat.sh/zfs
[gentoo wiki]: https://wiki.gentoo.org/wiki/ZFS
[how to enable zfs deduplication]: https://linuxhint.com/zfs-deduplication/
[oracle solaris zfs administration guide]: https://docs.oracle.com/cd/E19253-01/819-5461/index.html
[zfs support + kernel, best approach]: https://forum.manjaro.org/t/zfs-support-kernel-best-approach/33329/2
