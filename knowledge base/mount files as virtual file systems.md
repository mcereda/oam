# Mount files as virtual file systems

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Create the file.
truncate -s '10G' 'path/to/file'
dd if='/dev/zero' of='path/to/file' bs=4MiB count=250K status='progress'

# Create the file system on such file.
mkfs.ext4 'path/to/file'

# Create the mount point.
mkdir 'mount/point'

# Mount the file system.
# The 'loop' option is optional.
sudo mount -t 'ext4' -o 'loop' 'path/to/file' 'mount/point'
```

Prefer `truncate` to `dd` to let the file expand dynamically and be resized (both larger or smaller) without damaging data with `losetup` and `resize2fs`.

## Further readings

- [dd]
- [truncate]

## Sources

All the references in the [further readings] section, plus the following:

- [How do I create a file and mount it as a filesystem?]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[dd]: dd.md
[truncate]: truncate.md

<!-- Others -->
[how do i create a file and mount it as a filesystem?]: https://askubuntu.com/questions/85977/how-do-i-create-a-file-and-mount-it-as-a-filesystem#1402052
