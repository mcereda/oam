# `shred`

Overwrites devices or files in a way that helps prevent even extensive forensics from recovering the data.

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Pass on files more than 3 times.
shred -fn '10' 'path/to/file.1' … 'path/to/file.N'
shred --force --iterations '10' 'path/to/file.1' … 'path/to/file.N'

# Delete files and try hiding the shredding.
shred -uvz 'path/to/file.1' … 'path/to/file.N'
shred --remove --verbose --zero 'path/to/file.1' … 'path/to/file.N'

# Purge directories.
# `shred` does *not* accept directories as arguments.
find 'directory' -type f -exec shred -fu {} '+' \
&& find 'directory' -type d -empty -print -delete
```

## Further readings

- [Coreutils]

## Sources

All the references in the [further readings] section, plus the following:

- [`shred`: remove files more securely][shred: remove files more securely]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[coreutils]: coreutils.md

<!-- Upstream -->
[shred: remove files more securely]: https://www.gnu.org/software/coreutils/manual/html_node/shred-invocation.html
