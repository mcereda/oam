# `setfattr`

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install the tool.
apt install 'attr'
dnf install 'attr'

# Add extended attributes.
setfattr -n 'name' -v 'value' 'path/to/file.1' … 'path/to/file.N'

# Remove extended attributes.
setfattr -x 'name' 'path/to/file.1' … 'path/to/file.N'
```

## Further readings

- [`getfattr`][getfattr]

## Sources

All the references in the [further readings] section, plus the following:

- [`man` page][man page]
- [Tag files in GNU/Linux]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[getfattr]: getfattr.md
[tag files in gnu/linux]: tag%20files.md

<!-- Others -->
[man page]: https://linux.die.net/man/1/setfattr
