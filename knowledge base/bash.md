# Bourne Again SHell

## TL;DR

```shell
# Run a command or function on exit, kill or error.
trap "rm -f $tempfile" EXIT SIGTERM ERR
trap function-name EXIT SIGTERM ERR

# Disable CTRL-C
trap "" SIGINT

# Re-enable CTRL-C
trap - SIGINT
```

## Further readings

- [Trap]

[trap]: trap.md

## Sources

- [The Bash trap command]

[the bash trap command]: https://www.linuxjournal.com/content/bash-trap-command
