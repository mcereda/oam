# Bourne Again SHell

## TL;DR

```sh
# Declare functions.
functionName () { … }
function functionName { … }

# Declare functions on a single line.
functionName () { command1 ; … ; command N ; }

# Print exported variables only.
export -p

# Run a command or function on exit, kill or error.
trap "rm -f $tempfile" EXIT SIGTERM ERR
trap function-name EXIT SIGTERM ERR

# Disable CTRL-C.
trap "" SIGINT

# Re-enable CTRL-C.
trap - SIGINT

# Bash 3 and `sh` have no built-in means to convert case of a string, but the
# `awk`, `sed` or `tr` tools can be used instead.
echo $(echo "$name" |  tr '[:upper:]' '[:lower:]' )
echo $(tr '[:upper:]' '[:lower:]' <<< "$name")

# Bash 5 has a special parameter expansion for upper- and lowercasing strings.
echo ${name,,}
echo ${name^^}

# Add a clock to the top-right part of the terminal.
while sleep 1
do
  tput sc;
  tput cup 0 $(($(tput cols)-29))
  date
  tput rc
done &

# Show a binary clock.
watch -n 1 'echo "obase=2; `date +%s`" | bc'

# Fork bomb.
:(){ :|: & };:
```

## Startup files loading order

On startup:

1. (if login shell) `/etc/profile`
1. (if interactive and non login shell) `/etc/bashrc`
1. (if login shell) `~/.bash_profile`
1. (if login shell and `~/.bash_profile` not found) `~/.bash_login`
1. (if login shell and no `~/.bash_profile` nor `~/.bash_login` found) `~/.profile`
1. (if interactive and non login shell) `~/.bashrc`

Upon exit:

1. (if login shell) `~/.bash_logout`
1. (if login shell) `/etc/bash_logout`

## Functions

A function automatically returns the exit code of the last command in it.

## Check if a script is sourced by another

```sh
(return 0 2>/dev/null) && echo "this script is not sourced" || echo "this script is sourced"
```

## Further readings

- [Trap]
- [Upper- or lower-casing strings]

## Sources

- [The Bash trap command]
- [Bash startup files loading order]
- [How to detect if a script is being sourced]

<!-- internal references -->
[trap]: trap.md

<!-- external references -->
[bash startup files loading order]: https://youngstone89.medium.com/unix-introduction-bash-startup-files-loading-order-562543ac12e9
[how to detect if a script is being sourced]: https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced#28776166
[the bash trap command]: https://www.linuxjournal.com/content/bash-trap-command
[upper- or lower-casing strings]: https://scriptingosx.com/2019/12/upper-or-lower-casing-strings-in-bash-and-zsh/
