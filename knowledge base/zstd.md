# ZSTD

The `zstd`, `zstdmt`, `unzstd`, `zstdcat` utilities compress or decompress `.zst` files.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)

## TL;DR

```sh
# Compress folders into an archive.
zstd --compress -15 --rsyncable -r 'folder' -o 'archive.zst'

# Test archives.
zstd --test 'archive.zst'

# Print information about files in archives.
zstd --list 'archive.zst'

# Decompress archives.
zstd --decompress 'archive.zst'
```
