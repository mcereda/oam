# ZSH

## TL;DR

Startup file sequence:

1. `/etc/zshenv` and `${ZDOTDIR}/.zshenv`
1. **login** shells only: `/etc/zprofile` and `${ZDOTDIR}/.zprofile`
1. **interactive** shell only: `/etc/zshrc` and `${ZDOTDIR}/.zshrc`
1. **login** shells only: `/etc/zlogin` and `${ZDOTDIR}/.zlogin`
1. **upon exit**: `/etc/zlogout` and `${ZDOTDIR}/.zlogout`

Aliases are expanded when the function definition is parsed, not when the function is executed. Define aliases **before** functions to avoid problems.

```shell
# create a function
function_name () { … }
function function_name { … }
function function_name () { … }

# regex match
[[ $OSTYPE =~ "darwin" ]]
[[ $OSTYPE -regex-match "darwin" ]]

# find broken symlinks in the current directory
ls **/*(-@)

# print all shell and environment variables
( setopt posixbuiltin; set; )
```

## Alias expansion

When one writes an alias, one can also press `ctrl-x` followed by `a` to see the expansion of that alias.

## Arrays

```shell
# get a slice (negative are backwards)
echo ${ARRAY[2,-1]}

# get all folders up to a non folder, backwards
local COMMAND
local FOLDERS=()
for (( I = $# ; I >= 0 ; I-- )); do
  if [[ -d "${@[$I]}" ]]; then
    FOLDERS+="${@[$I]}"
  else
    COMMAND="${@[1,-$((${#FOLDERS}+1))]}"
    break
  fi
done
```

```shell
# make entries in PATH unique
# see https://til.hashrocket.com/posts/7evpdebn7g-remove-duplicates-in-zsh-path
typeset -aU path
```

## Tests

```shell
# regex match
[[ $OSTYPE =~ "darwin" ]]
[[ $OSTYPE -regex-match "darwin" ]]
```

## Find broken symlinks in the current directory

```shell
ls **/*(-@)
```

## Configuration

### Config files read order

1. `/etc/zshenv`; this cannot be overridden  
   subsequent behaviour is modified by the `RCS` and `GLOBAL_RCS` options:

   - `RCS` affects all startup files
   - `GLOBAL_RCS` only affects global startup files (those shown here with an path starting with a /)

   If one of the options is unset at any point, any subsequent startup file(s) of the corresponding type will not be read.  
   It is also possible for a file in `$ZDOTDIR` to re-enable `GLOBAL_RCS`.  
   Both `RCS` and `GLOBAL_RCS` are set by default

1. `$ZDOTDIR/.zshenv`
1. if the shell is a login shell:

   1. `/etc/zprofile`
   1. `$ZDOTDIR/.zprofile`

1. if the shell is interactive:

   1. `/etc/zshrc`
   1. `$ZDOTDIR/.zshrc`

1. if the shell is a login shell:

   1. `/etc/zlogin`
   1. `$ZDOTDIR/.zlogin`

1. when a login shell exits:

   1. `$ZDOTDIR/.zlogout`
   1. `/etc/zlogout`

   This happens with either an explicit exit via the `exit` or `logout` commands, or an implicit exit by reading `end-of-file` from the terminal.  
   However, if the shell terminates due to exec’ing another process, the files are not read. These are also affected by the `RCS` and `GLOBAL_RCS` options.  
   The `RCS` option affects the saving of history files, i.e. if `RCS` is unset when the shell exits, no history file will be saved.

If `ZDOTDIR` is unset, `HOME` is used instead. Files listed above as being in `/etc` may be in another directory, depending on the installation.

`/etc/zshenv` is run for **all** instances of zsh.  
it is a good idea to put code that does not need to be run for every single shell behind a test of the form `if [[ -o rcs ]]; then ...` so that it will not be executed when zsh is invoked with the `-f` option.

When `/etc/zprofile` is installed it will override `PATH` and possibly other variables that a user may set in `~/.zshenv`. Custom `PATH` settings and similar overridden variables can be moved to `~/.zprofile` or other user startup files that are sourced after the `/etc/zprofile`.  
If `PATH` must be set in `~/.zshenv` to affect things like non-login ssh shells, one method is to use a separate path-setting file that is conditionally sourced in `~/.zshenv` and also sourced from `~/.zprofile`.

### History

```shell
# The maximum number of events stored in the internal history list.
# If you use the HIST_EXPIRE_DUPS_FIRST option, setting this value larger than
# the SAVEHIST size will give you the difference as a cushion for saving
# duplicated history events.
HISTSIZE=1000

# The file to save the history in when an interactive shell exits.
# If unset, the history is not saved.
HISTFILE=~/.histfile

# The maximum number of history events to save in the history file.
SAVEHIST=1000
```

### Completion

```shell
# Enable completion
autoload -U compinit
compinit

# Enable cache for the completions
zstyle ':completion::complete:*' use-cache true
```

### Prompt management

```shell
# Enable prompt management
autoload -U promptinit
promptinit; prompt gentoo
```

### Automatic source of files in a folder

```shell
# Configuration modules.
# All files in the configuration folder will be automatically loaded in
# numeric order. The last file setting a value overrides the previous ones.
# Links are only sourced if their reference exists.
ZSH_MODULES_DIR="${ZSH_MODULES_DIR:-$HOME/.zshrc.d}"
if [[ -d "${ZSH_MODULES_DIR}" ]]
then
	for ZSH_MODULE in ${ZSH_MODULES_DIR}/*
	do
		[[ -r ${ZSH_MODULE} ]] && source "${ZSH_MODULE}"
	done
	unset ZSH_MODULE
fi
```

## Frameworks

- [antibody]
- [antigen]
- [ohmyzsh]
- [zplug]

## Plugins

- [fzf]
- [zsh-autosuggestions]
- [zsh-history-substring-search]
- [zsh-syntax-highlighting]

## Troubleshooting

> zsh compinit: insecure directories and files, run compaudit for list

```shell
compaudit | xargs chmod g-w
```

## Further readings

- [Substitutions]
- [ZSH compinit: insecure directories and files, run compaudit for list]
- [Pattern matching in a conditional expression]
- [Eemove duplicates in ZSH path]
- [Completion config example]
- [What should/shouldn't go in .zshenv, .zshrc, .zlogin, .zprofile, .zlogout?]
- [The Z Shell Manual]
- [Gentoo Wiki]
- [How can I convert an array into a comma separated string?]
- [How to list all variables names and their current values?]

[completion config example]: https://github.com/ThiefMaster/zsh-config/blob/master/zshrc.d/completion.zsh
[gentoo wiki]: https://wiki.gentoo.org/wiki/Zsh
[How can I convert an array into a comma separated string?]: https://stackoverflow.com/questions/53839253/how-can-i-convert-an-array-into-a-comma-separated-string
[pattern matching in a conditional expression]: https://unix.stackexchange.com/questions/553607/pattern-matching-in-a-zsh-conditional-expression
[remove duplicates in zsh path]: https://til.hashrocket.com/posts/7evpdebn7g-remove-duplicates-in-zsh-path
[substitutions]: http://zsh.sourceforge.net/Guide/zshguide05.html
[the z shell manual]: http://zsh.sourceforge.net/Doc/Release/
[what should/shouldn't go in .zshenv, .zshrc, .zlogin, .zprofile, .zlogout?]: https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout#487889
[zsh compinit: insecure directories and files, run compaudit for list]: https://github.com/zsh-users/zsh-completions/issues/433#issuecomment-619321054
[how to list all variables names and their current values?]: https://askubuntu.com/questions/275965/how-to-list-all-variables-names-and-their-current-values#275972

[antigen]: https://github.com/zsh-users/antigen
[fzf]: https://github.com/junegunn/fzf
[ohmyzsh]: https://github.com/ohmyzsh/ohmyzsh
[zplug]: https://github.com/zplug/zplug
[zsh-autosuggestions]: https://github.com/zsh-users/zsh-autosuggestions
[zsh-history-substring-search]: https://github.com/zsh-users/zsh-history-substring-search
[zsh-syntax-highlighting]: https://github.com/zsh-users/zsh-syntax-highlighting
