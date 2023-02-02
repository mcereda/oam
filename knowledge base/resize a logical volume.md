# Resize a Logical Volume

## TL;DR

```sh
# Disk partition: /dev/sda2
# Logical volume: rootvg-rootlv

# Extend the partition.
# Optional; required only when there isn't enough space left on the disk.
sudo growpart '/dev/sda' '2'

# Extend the physical volume.
# Optional; required only when there isn't enough space left in the volume.
sudo pvresize '/dev/sda2'

# Extend the file system to the desired size.
sudo lvextend -rL '48G' '/dev/mapper/rootvg-rootlv'
```

```yaml
#cloud-config

# 'growpart' only extends partitions to fill the available free space.
# At the time of writing there is no way to limit the expansion.
growpart:
  mode: auto
  devices:
    - /

runcmd:
  - pvresize '/dev/sda2'
  - lvextend -rL '48G' '/dev/mapper/rootvg-rootlv'
```
