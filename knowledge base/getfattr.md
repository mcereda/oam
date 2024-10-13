# `getfattr`

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Install the tool.
apt install 'attr'
dnf install 'attr'

# Get values for all attributes.
getfattr -d 'path/to/file.1' … 'path/to/file.N'

# Get values for specific extended attributes.
getfattr -n 'name' 'path/to/file.1' … 'path/to/file.N'
```

## Further readings

- [`setfattr`][setfattr]

### Sources

- [`man` page][man page]
- [Tag files in GNU/Linux]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Knowledge base -->
[setfattr]: setfattr.md
[tag files in gnu/linux]: tag%20files.md

<!-- Others -->
[man page]: https://linux.die.net/man/1/getfattr
