# Bourne Again SHell

## TL;DR

```sh
# Run a command or function on exit, kill or error.
trap "rm -f $tempfile" EXIT SIGTERM ERR
trap function-name EXIT SIGTERM ERR

# Disable CTRL-C
trap "" SIGINT

# Re-enable CTRL-C
trap - SIGINT

# Bash 3 and `sh` have no built-in means to convert case of a string, but the
# `awk`, `sed` or `tr` tools can be used instead.
echo $(echo "$name" |  tr '[:upper:]' '[:lower:]' )
echo $(tr '[:upper:]' '[:lower:]' <<< "$name")

# Bash 5 has a special parameter expansion for upper- and lowercasing strings.
echo ${name,,}
echo ${name^^}
```

## Further readings

- [Trap]
- [Upper- or lower-casing strings]

## Sources

- [The Bash trap command]

<!-- internal references -->
[trap]: trap.md

<!-- external references -->
[the bash trap command]: https://www.linuxjournal.com/content/bash-trap-command
[upper- or lower-casing strings]: https://scriptingosx.com/2019/12/upper-or-lower-casing-strings-in-bash-and-zsh/
