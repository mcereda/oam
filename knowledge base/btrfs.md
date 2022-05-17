# BTRFS

## TL;DR

```sh
# Create a volume with single metadata and double data blocks
# Useless in practice but a good example.
mkfs.btrfs --metadata single --data dup /dev/sdb

# Sparse a volume on multiple devices.
mkfs.btrfs --label data /dev/sd{a,c,d,e,f,g} --force \
&& echo "LABEL=data  /mnt/data  btrfs  compress=zstd  0  0"
   | tee -a /etc/fstab

# List all btrfs file systems.
btrfs filesystem show

# Show detailed `df` analogue for a filesystem.
btrfs filesystem df path/to/filesystem

# Give more details about usage.
btrfs filesystem usage path/to/filesystem

# Resize online volumes.
# -2g decreases, +2g increases.
btrfs filesystem resize -2g path/to/volume
btrfs filesystem resize max path/to/volume

# Add new devices to a filesystem.
btrfs device add /dev/sdf /mnt

# Remove devices from a filesystem.
btrfs device delete missing /mnt

# List subvolumes.
btrfs subvolume list /mnt

# Create subvolumes.
btrfs subvolume create /mnt/subvolume

# Create a readonly snapshot of a subvolume.
sudo btrfs subvolume snapshot -r /mnt/volume/data /mnt/volume/snapshot

# Mount subvolumes without mounting their main filesystem.
mount -o subvol=sv1 /dev/sdb /mnt

# Delete a subvolume.
sudo btrfs subvolume delete --commit-each /mnt/volume/data

# Deduplicate a volume's blocks.
sudo duperemove -Adrh --hashfile=/tmp/dr.hash /mnt/volume1 /media volume2
sudo jdupes --dedupe -rZ /mnt/volume1 /media volume2

# Send and receive snapshots.
sudo btrfs send /source/.snapshots/snap \
| sudo btrfs receive /destination/.snapshots/

# Show the properties of a subvolume/filesystem/inode/device.
btrfs property get -ts /path/to/subvolume
btrfs property get -tf /path/to/filesystem
btrfs property get -ti /path/to/inode
btrfs property get -td /path/to/device
btrfs property get /path/to/autoselected/type/of/resource

# Change a subvolume to RO on the fly.
btrfs property set -ts /path/to/subvolume ro true

# Show a volume's information.
sudo btrfs subvolume show /path/to/subvolume

# Check the compress ratio of a compressed volume.
sudo compsize /mnt/volume

# Show the status of a running or paused balance operation.
sudo btrfs balance status path/to/filesystem

# Balance all block groups.
# Slow: rewrites all blocks in filesystem.
sudo btrfs balance start path/to/filesystem
sudo btrfs balance start path/to/filesystem --bg --enqueue

# Balance data block groups which are less than 15% utilized.
# Run the operation in the background
sudo btrfs balance start --bg -dusage=15 path/to/filesystem

# Balance a max of 10 metadata chunks with less than 20% utilization and at
# least 1 chunk on a given device 'devid'.
# Get the device's devid with `btrfs filesystem show`.
sudo btrfs balance start -musage=20,limit=10,devid=devid path/to/filesystem

# Convert data blocks to the raid6 profile, and metadata to raid1c3.
sudo btrfs balance start -dconvert=raid6 -mconvert=raid1c3 path/to/filesystem

# Convert data blocks to raid1 skipping already converted chunks.
# Useful after a previous cancelled conversion operation.
sudo btrfs balance start -dconvert=raid1,soft path/to/filesystem

# Cancel, pause or resume a running or paused balance operation.
sudo btrfs balance cancel path/to/filesystem
sudo btrfs balance pause path/to/filesystem
sudo btrfs balance resume path/to/filesystem

# Enable quota.
sudo btrfs quota enable path/to/subvolume

# Show quota.
sudo btrfs qgroup show path/to/subvolume

# Convert ext3/ext4 to btrfs.
btrfs-convert /dev/sdb1

# Convert btrfs to ext3/ext4.
btrfs-convert -r /dev/sdb1
```

## Check differences between 2 snapshots

See also [snapper].

```sh
sudo btrfs send --no-data -p /old/snapshot /new/snapshot | sudo btrfs receive --dump

# requires you to be using snapper for your snapshots
sudo snapper -c config diff 445..446
```

## Further readings

- [Gentoo wiki]
- [Snapper]

## Sources

- [cheat.sh]
- [does btrfs have an efficient way to compare snapshots?]
- [determine if a btrfs subvolume is read-only]

[snapper]: snapper.md

[cheat.sh]: https://cheat.sh/btrfs
[gentoo wiki]: https://wiki.gentoo.org/wiki/Btrfs

[determine if a btrfs subvolume is read-only]: https://unix.stackexchange.com/questions/375645/determine-if-btrfs-subvolume-is-read-only#375646
[does btrfs have an efficient way to compare snapshots?]: https://serverfault.com/questions/399894/does-btrfs-have-an-efficient-way-to-compare-snapshots#419444
