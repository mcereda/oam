# Create, mount and use an encrypted disk

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Encrypt the device.
sudo cryptsetup luksFormat '/dev/sda'

# Open the encrypted device.
# 'mapper_name' is any name you want. It will be used by the device mapper.
sudo cryptsetup open '/dev/sda' 'mapper_name'

# Format the volume.
sudo mkfs.btrfs -f --label 'label' -m 'dup' '/dev/mapper/mapper_name'

# Mount the volume.
mkdir -p 'path/to/mount/point'
sudo mount -t 'filesystem' -o 'mount,options' '/dev/mapper/mapper_name' 'path/to/mount/point'

# Do something.
sudo chown 'user':'group' 'path/to/subvolume/in/mount/point'
btrfs subvolume create 'path/to/subvolume/in/mount/point'
parallel -j1 \
  'sudo btrfs send source/volume/.snapshots/{} | sudo btrfs receive destination/volume' \
  ::: $(ls source/volume/.snapshots)
parallel -q \
  btrfs subvolume snapshot -r volume/{} volume/.snapshots/$(date +%FT%T)/{} \
  ::: $(ls source/volume)

# Umount the volume.
sudo umount 'path/to/mount/point'

# Close the device.
sudo cryptsetup close '/dev/mapper/mapper_name'
```

## Further readings

- [`cryptsetup`][cryptsetup]
- [Encrypted root filesystem]

## Sources

All the references in the [further readings] section, plus the following:

- script: [Create an encrypted BTRFS device]
- script: [Create an encrypted ZFS device]

<!-- project's references -->

<!-- internal references -->

[further readings]: #further-readings

[cryptsetup]: cryptsetup.md
[encrypted root filesystem]: encrypted%20root%20filesystem.md

[create an encrypted btrfs device]: scripts/create-an-encrypted-btrfs-device.sh
[create an encrypted zfs device]: scripts/create-an-encrypted-btrfs-device.sh

<!-- external references -->
