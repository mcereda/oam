# `jot`

Generates sequential or random data.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Print 21 evenly spaced increasing numbers from -1 to 1.
jot '21' '-1' '1.00'
jot -p '2' '21' '-1' '1'

# Print all ASCII characters.
jot -c '128' '0'

# Print all strings from 'xaa' to 'xaz'.
jot -w 'xa%c' '26' 'a'

# Print 20 random 8-letter strings.
jot -r -c '160' 'a' 'z' | rs -g '0' '8'

# Create files containing a bunch of 'x' characters for exactly 1024 bytes of
# data.
jot -b 'x' '512' > 'file.txt'

# Print all lines of 80 characters or longer.
grep $(jot -s "" -b '.' '80') 'file.txt'
```

## Further readings

- [`man` page][man page]

## Sources

All the references in the [further readings] section, plus the following:

- [6 more terminal commands you should know]

<!--
  references
  -->

<!-- project -->
<!-- article sections -->
[further readings]: #further-readings

<!-- knowledge base -->
<!-- others -->
[6 more terminal commands you should know]: https://betterprogramming.pub/6-more-terminal-commands-you-should-know-3606cecdf8b6
[man page]: https://manned.org/jot
