# `lsblk`

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Install the tool.
dnf install 'util-linux'

# Show information about block devices.
lsblk
lsblk -a

# Also print other specific columns.
# Mind the '+' character at the beginning.
lsblk -o '+MODEL,SERIAL'

# Show only physical disks
lsblk -d

# Filter by major device numbers.
lsblk -I '8,259'
```

## Sources

- [`man` page][man page]

<!--
  References
  -->

<!-- Others -->
[man page]: https://linux.die.net/man/8/lsblk
