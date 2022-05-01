# BTRFS

## TL;DR

```shell
# create a volume with single metadata and double data blocks (useless but good example)
sudo mkfs.btrfs --metadata single --data dup /dev/sdb

# sparse a volume on multiple devices
sudo mkfs.btrfs --label data /dev/sd{a,c,d,e,f,g} --force
echo "LABEL=data  /mnt/data  btrfs  compress=zstd  0  0" | sudo tee -a /etc/fstab

# create a readonly snapshot of a subvolume
sudo btrfs subvolume snapshot -r /mnt/btrfs-volume/data /mnt/btrfs-volume/snapshot

# delete a subvolume
sudo btrfs subvolume delete --commit-each /mnt/btrfs-volume/data

# deduplicate a volume's blocks
sudo duperemove -Adrh --hashfile=/tmp/duperemove.hash /mnt/volume1 /mnt volume2
sudo jdupes --dedupe --recurse --softabort /mnt/btrfs-volume

# send and receive snapshots
sudo btrfs send /source-dir/.snapshots/snapshot | sudo btrfs receive /dest-dir/.snapshots/

# get the properties of a subvolume/filesystem/inode/device
btrfs property get -ts /path/to/subvolume
btrfs property get -tf /path/to/filesystem
btrfs property get -ti /path/to/inode
btrfs property get -td /path/to/device
btrfs property get /path/to/autoselected/type/of/resource

# change a subvolume to ro on the fly
btrfs property set -ts /path/to/subvolume ro true

# get info about a path
sudo btrfs subvolume show /path/to/subvolume

# check the compress ratio of a compressed path
sudo compsize /mnt/btrfs-volume
```

## Check differences between 2 snapshots

See also [snapper].

```shell
sudo btrfs send --no-data -p /old/snapshot /new/snapshot | sudo btrfs receive --dump

# requires you to be using snapper for your snapshots
sudo snapper -c config diff 445..446
```

## Further readings

- [Gentoo wiki]
- [Snapper]

[gentoo wiki]: https://wiki.gentoo.org/wiki/Btrfs
[snapper]: snapper.md

## Sources

- [does btrfs have an efficient way to compare snapshots?]
- [determine if a btrfs subvolume is read-only]

[determine if a btrfs subvolume is read-only]: https://unix.stackexchange.com/questions/375645/determine-if-btrfs-subvolume-is-read-only#375646
[does btrfs have an efficient way to compare snapshots?]: https://serverfault.com/questions/399894/does-btrfs-have-an-efficient-way-to-compare-snapshots#419444
