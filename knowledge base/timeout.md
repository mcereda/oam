# `timeout`

Start a command and kill it if still running after a given duration.<br/>
The command must not be a special built-in utility.

Part of GNU coreutils.

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Send the default TERM signal after 20s to a short-living command.
# It terminates before the given duration limit, so 'timeout' returns with the
# same exit status as the command.
timeout 20 sleep 1

# Send the INT signal after 5s to the 'sleep' command.
# Returns after 5 seconds with exit status 124 to indicate the sending of the
# interruption signal.
timeout -s INT 5 sleep 20

# Likewise, but the command will ignore the INT signal due to it being started
# via 'env --ignore-signal'.
# 'sleep' will terminate regularly after the full 20 seconds.
# 'timeout' will still return with exit status 124 to indicate the sending of
# the interruption signal.
timeout -s INT 5s env --ignore-signal=INT sleep 20

# Likewise, but will also send the KILL signal 3 seconds after the initial INT
# signal.
# 'sleep' is forcefully terminated after about 303 seconds (5m + 3s), and
# 'timeout' returns with an exit status of 137 to indicate the sending of the
# termination signal.
timeout -s INT -k 3s 5m env --ignore-signal=INT sleep 600
```

## Further readings

- [Website]

## Sources

All the references in the [further readings] section, plus the following:

- [cheat.sh]

<!--
  references
  -->

<!-- project -->
[website]: https://www.gnu.org/software/coreutils/timeout

<!-- article sections -->
[further readings]: #further-readings

<!-- knowledge base -->
<!-- others -->
[cheat.sh]: https://cheat.sh/timeout
