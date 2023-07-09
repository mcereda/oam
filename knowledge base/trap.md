# The Bash `trap` command

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Sources](#sources)

## TL;DR

```sh
# Run a command or function on exit, kill or error.
trap "rm -f $tempfile" EXIT SIGTERM ERR
trap function-name EXIT SIGTERM ERR

# Disable CTRL-C
trap "" SIGINT

# Re-enable CTRL-C
trap - SIGINT
```

## Sources

- [Using Bash traps in your scripts]
- [The Bash trap command]

<!--
  References
  -->

<!-- Others -->
[the bash trap command]: https://www.linuxjournal.com/content/bash-trap-command
[using bash traps in your scripts]: https://opensource.com/article/20/6/bash-trap
