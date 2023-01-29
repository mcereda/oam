# dd

Convert and copy a file.

## TL;DR

```sh
# Read 512 random Bytes for each iteration and save them .
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
```

## Sources

- [cheat.sh]

<!-- external references -->
[cheat.sh]: https://cheat.sh/dd
