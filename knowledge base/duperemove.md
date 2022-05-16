# Duperemove

Finds duplicated extents and submits them for deduplication.

When given a list of files, `duperemove` hashes their contents block by block and compares them.

When given the `-d` option, `duperemove` also submits duplicated extents for deduplication using the Linux kernel extent-same ioctl.

`duperemove` can store the hashes it computes in a hashfile. If given an existing hashfile in input, it only computes hashes for those files which have changed since the last run. This lets you run `duperemove` repeatedly on your data as it changes, without having to re-checksum unchanged data.

`duperemove` can also take input from `fdupes`, given the `--fdupes` option.

## TL;DR

```sh
# Recursively search for duplicated extents in a directory.
duperemove -hr path/to/directory

# Recursively deduplicate duplicated extents on a Btrfs or XFS filesystem.
# XFS deduplication is still experimental at the time of writing.
duperemove -Adhr path/to/directory

# Store extent hashes in a file.
# Hogs less memory and can be reused on subsequent runs.
duperemove -Adhr --hashfile=path/to/hashfile path/to/directory

# List the files tracked by hashfiles.
duperemove -L --hashfile=path/to/hashfile

# Limit threads; defaults are based on the host's cpus number.
# I/O threads are used for hashing and in the deduplication stage.
# CPU threads are used in the duplicate extent finding stage.
duperemove -Adhr --hashfile=path/to/hashfile \
  --io-threads=N --cpu-threads=N \
  path/to/directory
```

## Sources

- [Website]
- [cheat.sh]
- [manpage]

[cheat.sh]: https://cheat.sh/duperemove
[manpage]: https://markfasheh.github.io/duperemove/duperemove.html
[website]: https://markfasheh.github.io/duperemove/
