# The `truncate` command

Shrink or extend the size of a file to the specified size.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Empty the contents of files.
truncate -s 0 'file'

# Set the size of an existing file.
# if the file does not exist, create it anew of the specified size.
truncate -s 100 'file'
truncate --size 5k 'file'
truncate --size 10G 'file'

# Extend a file's size by 50 MiB and fill it with holes.
# Holes read as zero bytes.
truncate --size +50M 'file'

# Shrink a file by 2 GiB.
# Removes data from the end of file.
truncate --size -2G 'file'

# Empty the file's content, but do not create it if existing.
truncate --no-create --size 0 'file'
```

## Further readings

- [GNU's documentation]

## Sources

- [cheat.sh]

<!--
  References
  -->

<!-- Upstream -->
[gnu's documentation]: https://www.gnu.org/software/coreutils/truncate

<!-- Others -->
[cheat.sh]: https://cheat.sh/truncate
