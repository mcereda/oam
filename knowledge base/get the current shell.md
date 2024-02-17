# Get the current shell

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
   1. [Sources](#sources)

## TL;DR

```sh
# Full path of the current shell's executable with arguments.
ps -o 'command='

# Full path of the current shell's executable only.
ps -o 'comm='

# Only the executable name.
ps -co 'comm='

# Unreliable: if the SHELL variable is set by a previous shell, that one is the
# value that will be shown.
echo "$SHELL"
echo "$0"
```

## Further readings

### Sources

- [Remove the first line of a text file in Linux]

<!--
  References
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
<!-- Files -->
<!-- Upstream -->
<!-- Others -->
[remove the first line of a text file in linux]: https://www.baeldung.com/linux/remove-first-line-text-file
