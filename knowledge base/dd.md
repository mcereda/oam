# dd

Convert and copy a file.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Benchmark disks](#benchmark-disks)
1. [Sources](#sources)

## TL;DR

N and BYTES values may be followed by the following multiplicative suffixes:

| suffix      | multiplication      |
| ----------- | ------------------- |
| `c`         | 1                   |
| `w`         | 2                   |
| `b`         | 512                 |
| `kB`        | 1000                |
| `K`         | 1024                |
| `MB`        | 1000 * 1000         |
| `M` or `xM` | 1024 * 1024         |
| `GB`        | 1000 \* 1000 * 1000 |
| `G`         | 1024 \* 1024 * 1024 |

and so on for T, P, E, Z, Y.

```sh
# Read 512 random Bytes for each iteration and save them.
dd if='/dev/urandom' of='output/file' count=2 bs=512

# Read 1000 Bytes for each iteration and save them while watching the progress.
dd if='/input/file' of='output/file' count=4M bs=1k status='progress'

# Create a 1GiB file with nothing but zeros, ready to mkswap(8) it.
dd if='/dev/zero' of='/swapfile' count=1048576 bs=1024

# Make a bootable USB drive from an isohybrid file.
dd if=file.iso of=/dev/usb_drive status=progress

# Clone a drive to another drive with 4 MiB block.
# Ignore any error and show the progress.
dd if=/dev/source_drive of=/dev/dest_drive bs=4M conv=noerror status=progress

# Generate a system backup into an IMG file and show the progress:
dd if=/dev/drive_device of=path/to/file.img status=progress

# Restore a drive from an IMG file and show the progress:
dd if=path/to/file.img of=/dev/drive_device status=progress

# Create images from disks.
sudo dd if=/dev/mmcblk0 of=/tmp/mmcblk0.img conv=sync bs=4k
sudo dd if=/dev/sda conv=sync,noerror bs=64K | gzip -c > /mnt/sdb/disk.img.gz

# Write an image to disk.
sudo dd if=/tmp/mmcblk0.img of=/dev/mmcblk0 conv=fsync oflag=direct bs=4M status=progress

# Clone a disk on another disk.
sudo dd if=/dev/sda of=/dev/sdb conv=fsync bs=4M oflag=direct status=progress
```

## Benchmark disks

Use:

- a single, bigger file for throughput (write speed)
- multiple, smaller files for latency

```sh
dd \
  if=/dev/input.file of=/path/to/output.file \
  bs=block-size count=number-of-blocks \
  oflag=dsync status=progress
```

Examples:

```sh
dd if=/dev/zero of=/tmp/test1.img bs=1G count=1 oflag=dsync
dd if=/dev/zero of=/tmp/test2.img bs=64M count=1 oflag=dsync
dd if=/dev/zero of=/tmp/test3.img bs=1M count=256 conv=fdatasync
dd if=/dev/zero of=/tmp/test4.img bs=8k count=10k
dd if=/dev/zero of=/tmp/test4.img bs=512 count=1000 oflag=dsync
```

## Sources

- [cheat.sh]
- [Linux and Unix Test Disk I/O Performance With dd Command]

<!--
  References
  -->

<!-- Others -->
[cheat.sh]: https://cheat.sh/dd
[how to create a disk image in linux]: https://itstillworks.com/clone-hard-drive-ubuntu-6884403.html
[linux and unix test disk i/o performance with dd command]: https://www.cyberciti.biz/faq/howto-linux-unix-test-disk-performance-with-dd-command/
