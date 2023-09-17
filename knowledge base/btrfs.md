# BTRFS

Copy on write (COW) filesystem for Linux.<br/>
Features and benefits [here][introduction]. (Meta)Data profiles [here][mkfs.btrfs].

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Check differences between 2 snapshots](#check-differences-between-2-snapshots)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Create volumes with single metadata and double data blocks.
# Useless in practice, but a good example nonetheless.
sudo mkfs.btrfs --metadata "single" --data "dup" "/dev/sdb"

# Sparse one volume on multiple devices.
sudo mkfs.btrfs --label "data" /dev/sd{a,c,d,f,g} --force \
&& echo "LABEL=data  /mnt/data  btrfs  compress=zstd  0  0"
   | tee -a /etc/fstab
```

```sh
# List all BTRFS file systems.
sudo btrfs filesystem show

# Show detailed `df` analogue for filesystems.
sudo btrfs filesystem df "path/to/filesystem"
sudo btrfs filesystem df -h "path/to/filesystem"

# Show detailed `du` analogue for filesystems.
sudo btrfs filesystem du "path/to/filesystem"
sudo btrfs filesystem du --human-readable -s "path/to/filesystem"

# Give more details about filesystems' usage.
sudo btrfs filesystem usage "path/to/filesystem"

# Resize *online* volumes.
# -2g decreases, +2g increases.
sudo btrfs filesystem resize "-2g" "path/to/volume"
sudo btrfs filesystem resize "max" "path/to/volume"

# Add new devices to filesystems.
sudo btrfs device add "/dev/sdb" "path/to/filesystem"

# Remove devices from filesystems.
sudo btrfs device delete missing "path/to/filesystem"

# List subvolumes.
sudo btrfs subvolume list "path/to/subvolume"

# Create subvolumes.
btrfs subvolume create "${HOME}/path/to/subvolume"
sudo btrfs subvolume create "path/to/subvolume"

# Create snapshots of subvolumes.
btrfs subvolume snapshot "${HOME}/path/to/subvolume" "${HOME}/path/to/snapshot"
sudo btrfs subvolume snapshot -r "path/to/subvolume" "path/to/snapshot"

# Mount subvolumes without mounting their main filesystem.
sudo mount -o 'subvol=sv1' "/dev/sdb" "/mnt"

# Delete subvolumes.
sudo btrfs subvolume delete --commit-each "path/to/subvolume"

# Automatically compress new files and folders in directories in BTRFS mounts.
chattr +c 'path/to/dir'

# Disable Copy-on-Write for folders or subvolumes.
chattr +C 'path/to/dir'

# Deduplicate volumes' blocks.
sudo duperemove -Adrh --hashfile="/tmp/dr.hash" "path/1" … "path/n"
sudo jdupes --dedupe -rZ "path/1" … "path/n"

# Send and receive snapshots.
sudo btrfs send "path/to/source/snapshots" \
| sudo btrfs receive "path/to/destination/snapshots/folder/"

# Show the properties of subvolumes/filesystems/inodes/devices.
btrfs property get -ts "path/to/subvolume"
btrfs … -tf "path/to/filesystem"
btrfs … -ti "path/to/inode"
btrfs … -td "path/to/device"
btrfs … "path/to/autoselected/type/of/resource"

# Change RW subvolumes to RO ones on the fly.
btrfs property set -ts "path/to/subvolume" 'ro' 'true'

# Show subvolumes' information.
sudo btrfs subvolume show "path/to/subvolume"

# Check the compress ratio of compressed volumes.
# Requires `compsize`.
sudo compsize "path/to/subvolume"

# Show the status of running or paused balance operations.
sudo btrfs balance status "path/to/filesystem"

# Balance all block groups.
# Slow, because it rewrites *all* blocks in the filesystem.
sudo btrfs balance start "path/to/filesystem"
sudo btrfs balance start "path/to/filesystem" --bg --enqueue

# Balance data block groups which are less than 15% utilized.
# Run the operation in the background.
sudo btrfs balance start --bg -dusage='15' "path/to/filesystem"

# Balance a max of 10 metadata chunks with less than 20% utilization and at
# least 1 chunk on a given device 'devid'.
# Get the device's devid with `btrfs filesystem show`.
sudo btrfs balance start -musage='20,limit=10,devid=devid' "path/to/filesystem"

# Convert data blocks to the 'raid6' profile, and metadata to 'raid1c3'.
sudo btrfs balance start -dconvert='raid6' -mconvert='raid1c3' "path/to/filesystem"

# Convert data blocks to raid1 skipping already converted chunks.
# Useful after a previous cancelled conversion operation.
sudo btrfs balance start -dconvert='raid1,soft' "path/to/filesystem"

# Cancel, pause or resume running or paused balance operations.
sudo btrfs balance cancel "path/to/filesystem"
sudo btrfs balance pause "path/to/filesystem"
sudo btrfs balance resume "path/to/filesystem"

# Enable quota.
sudo btrfs quota enable "path/to/subvolume"

# Show quota.
sudo btrfs qgroup show "path/to/subvolume"

# Convert ext3/ext4 filesystems to BTRFS.
btrfs-convert "/dev/sdb1"

# Convert BTRFS filesystems to ext3/ext4.
btrfs-convert -r "/dev/sdb1"

# Create and activate a 2GB swapfile.
# Generic procedure.
truncate -s '0' 'path/to/swapfile'
chattr +C 'path/to/swapfile'
fallocate -l '2G' 'path/to/swapfile'
chmod '0600' 'path/to/swapfile'
mkswap 'path/to/swapfile'
swapon 'path/to/swapfile'

# Create and activate a 2GB swapfile.
# `btrfs` utility >= 6.1 only.
btrfs filesystem mkswapfile --size '2G' 'path/to/swapfile'
swapon 'path/to/swapfile'
```

## Check differences between 2 snapshots

See also [snapper].

```sh
sudo btrfs send --no-data -p "path/to/old/snapshot" "path/to/new/snapshot" \
| sudo btrfs receive --dump

# Requires one to be using `snapper` to manage the snapshots.
sudo snapper -c 'config' diff '445..446'
```

## Further readings

- Official [documentation]
- [Swapfile]
- [Gentoo wiki]
- [Snapper]

## Sources

All the references in the [further readings] section, plus the following:

- [cheat.sh]
- [Does BTRFS have an efficient way to compare snapshots?]
- [Determine if a BTRFS subvolume is read-only]

<!--
  References
  -->

<!-- Upstream -->
[documentation]: https://btrfs.readthedocs.io/en/latest/
[introduction]: https://btrfs.readthedocs.io/en/latest/Introduction.html
[mkfs.btrfs]: https://btrfs.readthedocs.io/en/latest/mkfs.btrfs.html
[swapfile]: https://btrfs.readthedocs.io/en/latest/Swapfile.html

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[snapper]: snapper.md

<!-- Others -->
[cheat.sh]: https://cheat.sh/btrfs
[determine if a btrfs subvolume is read-only]: https://unix.stackexchange.com/questions/375645/determine-if-btrfs-subvolume-is-read-only#375646
[does btrfs have an efficient way to compare snapshots?]: https://serverfault.com/questions/399894/does-btrfs-have-an-efficient-way-to-compare-snapshots#419444
[gentoo wiki]: https://wiki.gentoo.org/wiki/Btrfs
