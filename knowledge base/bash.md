# Bourne Again SHell

## Table of contents <!-- omit in toc -->

1. [TL;DR](#tldr)
1. [Startup files loading order](#startup-files-loading-order)
1. [Functions](#functions)
1. [Substitutions](#substitutions)
   1. [!! (command substitution)](#-command-substitution)
   1. [^^ (caret substitution)](#-caret-substitution)
1. [Here documents](#here-documents)
1. [Keys combinations](#keys-combinations)
1. [Check if a script is sourced by another](#check-if-a-script-is-sourced-by-another)
1. [Gotchas](#gotchas)
   1. [Exist statuses of killed commands](#exist-statuses-of-killed-commands)
   1. [Go incognito](#go-incognito)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

Shortcuts:

| Shortcut     | Action                                                  |
| ------------ | ------------------------------------------------------- |
| `!!`         | Insert the previous command in the current prompt.      |
| `Alt` + `.`  | Insert the last argument in the current prompt.         |
| `Ctrl` + `L` | Clear the terminal.                                     |
| `Ctrl` + `R` | Search **backwards** in the history one step at a time. |
| `Ctrl` + `Z` | Send the current foreground task to background.         |

Get help:

```sh
# Get a brief summary about commands.
help 'nano'

# Get detailed information about commands.
man 'parallel'
```

Session management:

```sh
# Clean the console.
clear

# Print the current directory.
pwd

# Change the current directory.
cd
cd /bin
cd ..

# Create local variables.
VAR_NAME="value"

# Convert local variables in environment ones.
export VAR_NAME
export VAR_NAME="value"

# Deletes variables.
unset MY_FRIENDS

# Add directories to the current executables locations.
export PATH="${PATH}:/home/user/bin"
export PATH="/home/user/bin:${PATH}"

# Show the path of executables in $PATH.
which 'redis-cli'

# Show the path, man pages, source code, etc of executables in $PATH.
whereis nano

# List existing aliases.
alias

# Create aliases.
alias redo='$(history -p !!)'

# Remove aliases.
unalias redo

# Print all environment variables.
env

# Print all local *and* environment variables.
set
( set -o posix ; set )

# Print exported variables only.
export -p

# Logout after 3 minutes of inactivity.
TMOUT=180
```

Piping:

```sh
# Use the output of a command as the input of another.
tail 'file.txt' | grep 'search'

# Save the output of command 'a' as 'file.txt'.
# This *overwrites* already existing files with that name.
a > 'file.txt'

# Append the output of command 'a' to 'file.txt'.
a >> 'file.txt'
```

Arrays:

```sh
# Declare arrays.
ARRAY=(
  "first_element"
  "second_element" "nth_element"
)

# Get the length of arrays.
# A.K.A. number of elements.
ARRAY_LEN=${#ARRAY[@]}

# Access all elements in arrays with referencing.
echo ${ARRAY[@]}
echo ${ARRAY[*]}

# Access the last value of arrays.
echo ${ARRAY[-1]}
echo ${ARRAY: -1}

# Get a slice of 4 elements from an array.
# Start from the element with index number 2.
echo ${ARRAY:2:4}
```

Functions:

```sh
# Declare functions.
functionName () { … }
function functionName { … }

# Declare functions on a single line.
functionName () { command1 ; … ; command N ; }

# Get all the arguments in input.
echo $@
```

Error management:

```sh
# Run a command or function on exit, kill or error.
trap "rm -f $tempfile" EXIT SIGTERM ERR
trap function-name EXIT SIGTERM ERR

# Disable CTRL-C.
trap "" SIGINT

# Re-enable CTRL-C.
trap - SIGINT
```

Job control:

```sh
# Print a list of background tasks.
jobs

# Bring a background task in the foreground.
fg
fg 'task_number'
```

Other snippets:

```sh
# Copy and paste *on Linux*.
echo "Hello my friend!" | xclip \
&& xclip -o >> pasted_text.txt

# Copy and paste *on Darwin*.
echo "Hello my friend!" | pbcopy \
&& pbpaste >> pasted_text.txt

# Of all the arguments in input, return only those which are existing directories.
DIRECTORIES=()
for (( I = $# ; I >= 0 ; I-- )); do
  if [[ -d ${@[$I]} ]]; then
    DIRECTORIES+=${@[$I]}
  else
    local COMMAND="${@:1: 1-$I}"
    break
  fi
done

# Bash 3 and `sh` have no built-in means to convert case of a string, but the
# `awk`, `sed` or `tr` tools can be used instead.
echo $(echo "$name" |  tr '[:upper:]' '[:lower:]' )
echo $(tr '[:upper:]' '[:lower:]' <<< "$name")

# Bash 5 has a special parameter expansion for upper- and lowercasing strings.
echo ${name,,}
echo ${name^^}

# Leverage brace expansion to write less duplicated stuff.
mv /tmp/readme.md{,.backup}  # = mv /tmp/readme.md /tmp/readme.md.backup
cp a{1,2,3}.txt backup-dir   # = cp a1.txt a2.txt a3.txt backup-dir
cp a{1..3}.txt backup-dir    # = cp a1.txt a2.txt a3.txt backup-dir

# Add a clock to the top-right part of the terminal.
while sleep 1
do
  tput sc;
  tput cup 0 $(($(tput cols)-29))
  date
  tput rc
done &

# Show a binary clock.
watch -n 1 'echo "obase=2; $(date +%s)" | bc'

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

## Substitutions

### !! (command substitution)

Substitutes `!!` with the last command in your history

```sh
$ echo 'hallo!'
hallo!

$ !!
echo 'hallo!'
hallo!

$ sudo !!
sudo echo 'hallo!'
[sudo] password for user:
hallo!
```

### ^^ (caret substitution)

Re-runs a command replacing a string.

```sh
$ sudo apt search tmux
…

$ ^search^show
sudo apt show tmux
…
```

## Here documents

A _Here document_ (_heredoc_) is a type of redirection that allows you to pass multiple lines of input to a command.

```sh
[COMMAND] <<[-] 'DELIMITER'
  HERE-DOCUMENT
DELIMITER
```

- the first line must start with an **optional command** followed by the special redirection operator `<<` and the **delimiting identifier**
- one can use **any string** as a delimiting identifier, the most commonly used being `EOF` or `END`
- if the delimiting identifier is **unquoted**, the shell will substitute all variables, commands and special characters before passing the here-document lines to the command
- appending a **minus sign** to the redirection operator (`<<-`), will cause all leading tab characters to be **ignored**<br/>
  this allows one to use indentation when writing here-documents in shell scripts<br/>
  leading whitespace characters are not allowed, only tabs are
- the here-document block can contain strings, variables, commands and any other type of input
- the last line must end with the delimiting identifier<br/>
  white space in front of the delimiter is not allowed

```sh
$ cat << EOF
The current working directory is: $PWD
You are logged in as: $(whoami)
EOF
The current working directory is: /home/user
You are logged in as: user
```

```sh
$ cat <<-'EOF' | sed 's/l/e/g' > file.txt
  Hello
  World
EOF
$ cat file.txt
Heeeo
Wored
```

## Keys combinations

- `Ctrl+L`: clear the screen (instead of typing `clear`)
- `Ctrl+R`: reverse search your Bash history for a command that you have already run and wish to run again

## Check if a script is sourced by another

```sh
(return 0 2>/dev/null) \
&& echo "this script is not sourced" \
|| echo "this script is sourced"
```

## Gotchas

### Exist statuses of killed commands

The exit status of a killed command is **128 + _n_** if the command was killed by signal _n_:

```sh
$ pgrep tryme.sh
880
$ kill -9 880
$ echo $?
137
```

### Go incognito

See [How do I open an incognito bash session] on [unix.stackexchange.com]

```sh
HISTFILE=
```

You can also avoid recording a single command simply preceding it with space

```sh
echo $RECORDED
 echo $NOT_RECORDED
```

## Further readings

- [Trap]
- [Upper- or lower-casing strings]

## Sources

All the references in the [further readings] section, plus the following:

- [The Bash trap command]
- [Bash startup files loading order]
- [How to detect if a script is being sourced]
- [The essential Bash cheat sheet]
- [Speed up your command line navigation]
- [6 Bash tricks you can use daily]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[trap]: trap.md

<!-- Others -->
[6 bash tricks you can use daily]: https://medium.com/for-linux-users/6-bash-tricks-you-can-use-daily-a32abdd8b13
[bash startup files loading order]: https://youngstone89.medium.com/unix-introduction-bash-startup-files-loading-order-562543ac12e9
[how to detect if a script is being sourced]: https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced#28776166
[speed up your command line navigation]: https://blog.jread.com/posts/speed-up-your-command-line-navigation-part-1/
[the bash trap command]: https://www.linuxjournal.com/content/bash-trap-command
[the essential bash cheat sheet]: https://betterprogramming.pub/the-essential-bash-cheat-sheet-e1c3df06560
[upper- or lower-casing strings]: https://scriptingosx.com/2019/12/upper-or-lower-casing-strings-in-bash-and-zsh/

<!-- FIXME -->

[add directory to $path if it's not already there]: https://superuser.com/questions/39751/add-directory-to-path-if-its-not-already-there
[append elements to an array]: https://linuxhint.com/bash_append_array/
[bash-heredoc]: https://linuxize.com/post/bash-heredoc
[bashrc ps1 generator]: http://bashrcgenerator.com/
[check if a string represents a valid path]: https://unix.stackexchange.com/questions/214886/check-if-string-represents-valid-path-in-bash
[command line arguments in a shell script]: https://tecadmin.net/tutorial/bash-scripting/bash-command-arguments/
[find out the exit codes of all piped commands]: https://www.cyberciti.biz/faq/unix-linux-bash-find-out-the-exit-codes-of-all-piped-commands
[histsize vs histfilesize]: https://stackoverflow.com/questions/19454837/bash-histsize-vs-histfilesize#19454838
[how do i open an incognito bash session]: https://unix.stackexchange.com/questions/158933/how-do-i-open-an-incognito-bash-session/158937#158937
[how to find a bash shell array length]: https://www.cyberciti.biz/faq/finding-bash-shell-array-length-elements/
[how to slice an array]: https://stackoverflow.com/questions/1335815/how-to-slice-an-array-in-bash#1336245
[is there a way of reading the last element of an array?]: https://unix.stackexchange.com/questions/198787/is-there-a-way-of-reading-the-last-element-of-an-array-with-bash#198789
[linux-terminal-trick]: https://opensource.com/article/20/1/linux-terminal-trick
[printing array elements in reverse]: https://www.unix.com/shell-programming-and-scripting/267967-printing-array-elements-reverse.html
[regular expressions in a case statement]: https://stackoverflow.com/questions/9631335/regular-expressions-in-a-bash-case-statement#9631449
[reverse an array]: https://unix.stackexchange.com/questions/412868/bash-reverse-an-array
[set]: https://ss64.com/bash/set.html
[slice of positional parameters]: https://unix.stackexchange.com/questions/82060/bash-slice-of-positional-parameters#82061
[how to list all variables names and their current values?]: https://askubuntu.com/questions/275965/how-to-list-all-variables-names-and-their-current-values#275972

[linuxize.com]: https://linuxize.com
[opensource.com]: https://opensource.com
[unix.stackexchange.com]: https://unix.stackexchange.com

[bash prompt generator]: https://robotmoon.com/bash-prompt-generator/
