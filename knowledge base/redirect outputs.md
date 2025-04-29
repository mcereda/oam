# Redirect outputs

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)

## TL;DR

Pipes are set up **before** the I/O redirections are interpreted.<br/>
The sequence of I/O redirections is interpreted **left-to-right**.

```sh
command 2>&1 >'/dev/null' | grep 'something'
command 2>'/dev/stdout' 1>'/dev/null' | grep 'something'

# Swap the standard error and standard output over, then close the spare descriptor used for the swap.
command 3>&1 1>&2 2>&3 3>&-
```

## Further readings

- [How can I pipe stderr, and not stdout?]
- [Pipe only STDERR through a filter]
- [File Descriptors in Bourne shell]

<!--
  Reference
  ═╬═Time══
  -->

<!-- Others -->
[File Descriptors in Bourne shell]: https://mixedvolume.blogspot.com/2004/12/file-descriptors-in-bourne-shell.html
[How can I pipe stderr, and not stdout?]: https://stackoverflow.com/questions/2342826/how-can-i-pipe-stderr-and-not-stdout
[Pipe only STDERR through a filter]: https://stackoverflow.com/questions/3618078/pipe-only-stderr-through-a-filter#52575087
