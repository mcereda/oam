# Mount and use an encrypted device

## Table of contents <!-- omit in toc -->

1. [TL:DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL:DR

```sh
# Encrypt the device.
cryptsetup luksFormat '/dev/sda'

# Open the encrypted device.
# 'mapper_name' is any name you want. It will be used by the device mapper.
cryptsetup open '/dev/sda' 'mapper_name'

# Format the volume.
mkfs.btrfs -f --label 'label' '/dev/mapper/mapper_name'

# Mount the volume.
mkdir -p 'path/to/mount/point'
mount -t 'filesystem' -o 'mount,options' '/dev/mapper/mapper_name' 'path/to/mount/point'

# Do something.
btrfs subvolume create 'path/to/subvolume/in/mount/point'
chown 'user':'group' 'path/to/subvolume/in/mount/point'

# Umount the volume.
umount 'path/to/mount/point'

# Close the device.
cryptsetup close '/dev/mapper/mapper_name'
```

## Further readings

## Sources

All the references in the [further readings] section, plus the following:

- script: [Create an encrypted BTRFS device]
- script: [Create an encrypted ZFS device]

<!-- project's references -->
<!-- internal references -->

[further readings]: #further-readings

[create an encrypted btrfs device]: scripts/create-an-encrypted-btrfs-device.sh
[create an encrypted zfs device]: scripts/create-an-encrypted-btrfs-device.sh

<!-- external references -->
