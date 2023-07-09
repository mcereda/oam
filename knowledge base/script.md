# `script`

Make a typescript file (a.k.a. log a.k.a. recording) of a terminal session.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Start recording.
# Defaults to a file named "typescript".
script
script 'file.log'

# Stop recording.
exit

# Append to an existing file.
script -a 'file.log'

# Execute quietly.
# Avoids 'start' and 'done' messages.
script -q 'file.log'

# Flush output after each write.
script -f
```

## Further readings

- [6 more terminal commands you should know]
- [`man`][man]

## Sources

All the references in the [further readings] section, plus the following:

- [cheat.sh]

<!--
  references
  -->

<!-- upstream -->
<!-- article sections -->
[further readings]: #further-readings

<!-- knowledge base -->
<!-- others -->
[6 more terminal commands you should know]: https://betterprogramming.pub/6-more-terminal-commands-you-should-know-3606cecdf8b6
[cheat.sh]: https://cheat.sh/script
[man]: https://manned.org/script
