# `cmp`

Compares two files byte by byte.

Prints the line and the character number where the two files diverge.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Print only lines present in both file1 and file2.
cmp 'path/to/file1' 'path/to/file2'
```

## Further readings

- [`comm`][comm]
- [man page]

## Sources

All the references in the [further readings] section, plus the following:

- [6 more terminal commands you should know]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[comm]: comm.md

<!-- Others -->
[6 more terminal commands you should know]: https://betterprogramming.pub/6-more-terminal-commands-you-should-know-3606cecdf8b6
[man page]: https://linux.die.net/man/1/cmp
