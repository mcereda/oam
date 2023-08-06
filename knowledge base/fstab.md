# Fstab

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```txt
# By label.
# Get the label of a device: `e2label '/dev/sdc1'`
# Mount a device by label: `mount -L 'seagate_2tb_usb' '/media/usb'`
LABEL=seagate_2tb_usb  /media/usb  ext3  defaults  0 0

# By UUID.
# Get the UUID of a device: `vol_id --uuid '/dev/sdb2'`
# Mount a device by UUID: `mount -U '41c22818-fbad-4da6-8196-c816df0b7aa8' '/disk2p2'`
UUID=41c22818-fbad-4da6-8196-c816df0b7aa8  /disk2p2  ext3  defaults,errors=remount-ro   0 1

# Remote NFS shares.
# Mount a device: `mount 'nas.local:/volume1/media' '/media'`
nas.local:/volume1/media  /media  nfs4  noauto,user  0 0
```

## Sources

- [Mount a disk partition using LABEL]
- [Mount a disk partition using UUID]

<!--
  References
  -->

<!-- Others -->
[mount a disk partition using label]: https://www.cyberciti.biz/faq/rhel-centos-debian-fedora-mount-partition-label/
[mount a disk partition using uuid]: https://www.cyberciti.biz/faq/linux-finding-using-uuids-to-update-fstab/
