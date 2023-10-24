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
script -T 'timing.script' 'file.script'

# Record quietly.
# Avoids 'start' and 'done' messages.
script -q 'file.script'

# Stop recording.
exit
^D

# Append to an existing file.
script -a 'file.script'

# Flush output after each write.
script -f

# Replay the session.
scriptreplay -t 'timing.script' 'file.script'
scriptreplay -T 'timing.script' -B 'file.script'
```

## Further readings

- [6 more terminal commands you should know]
- [`man`][man]

## Sources

All the references in the [further readings] section, plus the following:

- [cheat.sh]
- [How to replay terminal sessions recorded with the Linux script command]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Others -->
[6 more terminal commands you should know]: https://betterprogramming.pub/6-more-terminal-commands-you-should-know-3606cecdf8b6
[cheat.sh]: https://cheat.sh/script
[how to replay terminal sessions recorded with the linux script command]: https://www.redhat.com/sysadmin/playback-scriptreplay
[man]: https://manned.org/script
