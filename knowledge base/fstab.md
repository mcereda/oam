# Fstab

## TL;DR

```plaintext
# by label
# e2label /dev/sdc1
# mount -L seagate_2tb_usb /media/usb
LABEL=seagate_2tb_usb  /media/usb  ext3  defaults  0 0

# by uuid
# vol_id --uuid /dev/sdb2
# mount -U 41c22818-fbad-4da6-8196-c816df0b7aa8 /disk2p2
UUID=41c22818-fbad-4da6-8196-c816df0b7aa8  /disk2p2  ext3  defaults,errors=remount-ro   0 1
```

## Further readings

- [Mount a disk partition using LABEL]
- [Mount a disk partition using UUID]

[mount a disk partition using label]: https://www.cyberciti.biz/faq/rhel-centos-debian-fedora-mount-partition-label/
[mount a disk partition using uuid]: https://www.cyberciti.biz/faq/linux-finding-using-uuids-to-update-fstab/
