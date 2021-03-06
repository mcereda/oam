# ZSH

## TL;DR

Startup file sequence:

1. `/etc/zshenv` and `${ZDOTDIR}/.zshenv`
1. **login** shells only: `/etc/zprofile` and `${ZDOTDIR}/.zprofile`
1. **interactive** shell only: `/etc/zshrc` and `${ZDOTDIR}/.zshrc`
1. **login** shells only: `/etc/zlogin` and `${ZDOTDIR}/.zlogin`
1. **upon exit**: `/etc/zlogout` and `${ZDOTDIR}/.zlogout`

Aliases are expanded when the function definition is parsed, not when the function is executed. Define aliases **before** functions to avoid problems.

```sh
# Quoting.
"$scalar"
"${array[@]}"
"${(@)array}"

# Create a function.
function_name () { … }
function function_name { … }
function function_name () { … }

# Regex match.
[[ "$OSTYPE" =~ "darwin" ]]
[[ "$OSTYPE" -regex-match "darwin" ]]

# Find broken symlinks in the current directory.
ls **/*(-@)

# Print all shell and environment variables.
setopt posixbuiltins && set

# Make entries unique in an array.
typeset -aU path

# Show all active key bindings.
bindkeys
```

## Alias expansion

When one writes an alias, one can also press `ctrl-x` followed by `a` to see the expansion of that alias.

## Parameter expansion

Parameter expansions can involve flags like `${(@kv)aliases}` and other operators such as `${PREFIX:-"/usr/local"}`. Parameter expansions can also be nested.

If the parameter is a **scalar** then the value, if any, is substituted:

```sh
$ scalar='hello'
$ echo "$scalar"
hello
```

The braces are required if the expansion is to be followed by a letter, digit or underscore that is not to be interpreted as part of name:

```sh
$ echo "${scalar}_world"
hello_world
```

If the parameter is an **array**, then the value of each element is substituted, one element per word:

```sh
$ typeset -a array=( 'hello' 'world' )
$ echo "${array[@]}"
hello world
```

The two forms are equivalent:

```sh
$ echo "${(@)array}"
hello world
```

### Substitution

#### Check if set

If _name_ is set then its value is substituted by _1_, otherwise by _0_:

```sh
$ typeset name='tralala'
$ echo "${+name}"
1

$ name=''
$ echo "${+name}"
1

$ unset name
$ echo "${+name}"
0
```

#### Provide a default value

If _name_ is set then substitute its value, otherwise substitute _word_:

```sh
$ name='tralala'
$ echo "${name-word}"
tralala

$ name=''
$ echo "${name-word}"
(empty line)

$ unset name
$ echo "${name-word}"
word
```

In the second form:

- only substitute its value if _name_ is non-null, and
- _name_ may be omitted, in which case _word_ is **always** substituted:

```sh
$ name='tralala'
$ echo "${name:-word}"
tralala

$ name=''
$ echo "${name:-word}"
word

$ unset name
$ echo "${name:-word}"
word
```

#### Just substitute

If _name_ is set then substitute _word_, otherwise substitute nothing:

```sh
$ name='tralala'
$ echo "${name+word}"
word

$ name=''
$ echo "${name+word}"
word

$ unset name
$ echo "${name+word}"
(empty line)
```

In the second form, only substitute its value if _name_ is non-null:

```sh
$ name='tralala'
$ echo "${name:+word}"
word

$ name=''
$ echo "${name:+word}"
(empty line)

$ unset name
$ echo "${name:+word}"
(empty line)
```

#### Set a default value and substitute

In the first form, if _name_ is unset then set it to _word_:

```sh
$ name='tralala'         # value: 'tralala'
$ echo "${name=word}"
tralala

$ name=''                # value: ''
$ echo "${name=word}"
(empty line)

$ unset name             # unset
$ echo "${name=word}"    # value: 'word'
word

$ echo "$name"
word
```

In the second form, if _name_ is unset or null then set it to _word_:

```sh
$ name='tralala'         # value: 'tralala'
$ echo "${name:=word}"
tralala

$ name=''                # value: ''
$ echo "${name:=word}"   # value: 'word'
word

$ echo "$name"
word

$ unset name             # unset
$ echo "${name:=word}"   # value: 'word'
word

$ echo "$name"
word
```

In the third form, unconditionally set _name_ to _word_:

```sh
$ name='tralala'         # value: 'tralala'
$ echo "${name::=word}"
word

$ echo "$name"
word

$ name=''                # value: ''
$ echo "${name::=word}"  # value: 'word'
word

$ echo "$name"
word

$ unset name             # unset
$ echo "${name::=word}"  # value: 'word'
word

$ echo "$name"
word
```

#### Fail on missing value

In the first form, if _name_ is set then substitute its value, otherwise print _word_ and exit from the shell.

```sh
$ name='tralala'
$ echo "${name?word}"
tralala

$ name=''
$ echo "${name?word}"
(empty line)

$ unset name
$ echo "${name?word}"
zsh: name: word
```

In the second form, substitute its value only if _name_ is both set and non-null:

```sh
$ name='tralala'
$ echo "${name:?word}"
tralala

$ name=''
$ echo "${name:?word}"
zsh: name: word

$ unset name
$ echo "${name:?word}"
zsh: name: word
```

Interactive shells return to the prompt.

If _word_ is omitted, a standard message is printed in its place:

```sh
$ name=''
$ echo "${name:?}"
zsh: name: parameter not set
```

### Matching and replacement

In the following expressions, when _name_ is an array and the substitution is not quoted, or if the `(@)` flag or the `name[@]` syntax is used, matching and replacement is performed **on each array element** separately.

FIXME

## Arrays

```sh
# Get a slice of an array.
# Negative numbers count backwards.
echo "${ARRAY[2,-1]}"

# Get all folders up to a non folder, backwards.
local COMMAND
local FOLDERS=()
for (( I = $# ; I >= 0 ; I-- ))
do
	if [[ -d "${@[$I]}" ]]
	then
		FOLDERS+="${@[$I]}"
	else
		COMMAND="${@[1,-$((${#FOLDERS}+1))]}"
		break
	fi
done

# Make entries unique in an array.
# See https://til.hashrocket.com/posts/7evpdebn7g-remove-duplicates-in-zsh-path.
typeset -aU path
```

## Tests

```sh
# Regex match.
[[ "$OSTYPE" =~ "darwin" ]]
[[ "$OSTYPE" -regex-match "darwin" ]]
```

## Find broken symlinks in the current directory

```sh
ls **/*(-@)
```

## Key bindings

```sh
# Show all active key bindings.
bindkeys

# Make the home, end and delete key work as expected.
# To know the code of a key execute `cat`, press enter, the key, and Ctrl+C.
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char
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
   However, if the shell terminates due to exec'ing another process, the files are not read. These are also affected by the `RCS` and `GLOBAL_RCS` options.  
   The `RCS` option affects the saving of history files, i.e. if `RCS` is unset when the shell exits, no history file will be saved.

If `ZDOTDIR` is unset, `HOME` is used instead. Files listed above as being in `/etc` may be in another directory, depending on the installation.

`/etc/zshenv` is run for **all** instances of zsh.  
it is a good idea to put code that does not need to be run for every single shell behind a test of the form `if [[ -o rcs ]]; then ...` so that it will not be executed when zsh is invoked with the `-f` option.

When `/etc/zprofile` is installed it will override `PATH` and possibly other variables that a user may set in `~/.zshenv`. Custom `PATH` settings and similar overridden variables can be moved to `~/.zprofile` or other user startup files that are sourced after the `/etc/zprofile`.  
If `PATH` must be set in `~/.zshenv` to affect things like non-login ssh shells, one method is to use a separate path-setting file that is conditionally sourced in `~/.zshenv` and also sourced from `~/.zprofile`.

### History

```sh
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

```sh
# Enable completion.
autoload -U compinit
compinit

# Enable cache for the completions.
zstyle ':completion::complete:*' use-cache true
```

### Prompt management

```sh
# Enable prompt management.
autoload -U promptinit
promptinit; prompt theme-name
```

### Automatic source of files in a folder

```sh
# Configuration modules.
# All files in the configuration folder will be automatically loaded in
# numeric order. The last file setting a value overrides the previous ones.
# Links are only sourced if their reference exists.
: "${ZSH_MODULES_DIR:-$HOME/.zshrc.d}"
if [[ -d "$ZSH_MODULES_DIR" ]]
then
	for ZSH_MODULE in "$ZSH_MODULES_DIR"/*
	do
		[[ -r "$ZSH_MODULE" ]] && source "$ZSH_MODULE"
	done
	unset ZSH_MODULE
fi
```

## Frameworks

- [antibody]
- [antidote]
- [antigen]
- [ohmyzsh]
- [zcomet]
- [zplug]

## Plugins

[Awesome zsh plugins] is a comprehensive list of various plugins for ZSH.

What follows are some I always add to my setup:

- [fzf]
- [zsh-autosuggestions]
- [zsh-completions]
- [zsh-history-substring-search]
- [zsh-syntax-highlighting]

## Troubleshooting

### The delete, end and/or home keys are not working as intended

Some setting or plugin changed the key binding. Reassign them to obtain the expected behaviour:

```sh
bindkey  "^[[H"   beginning-of-line
bindkey  "^[[F"   end-of-line
bindkey  "^[[3~"  delete-char
```

> To know the code of a key, execute cat, press enter, press the key, then Ctrl+C.

### Compinit warnings of insecure directories and files

Compinit is complaining of some critical files being group writable. Running `compaudit` will list those files. Just use it to remove the group's write permission:

```sh
compaudit | xargs chmod g-w
```

## Further readings

- [Substitutions]
- [ZSH compinit: insecure directories and files, run compaudit for list]
- [Pattern matching in a conditional expression]
- [Remove duplicates in ZSH path]
- [Completion config example]
- [What should/shouldn't go in .zshenv, .zshrc, .zlogin, .zprofile, .zlogout?]
- [The Z Shell Manual]
- [Gentoo Wiki]
- [How can I convert an array into a comma separated string?]
- [How to list all variables names and their current values?]
- [Zsh delete keybinding]
- [Fix key settings (Home/End/Insert/Delete) in .zshrc when running Zsh in Terminator Terminal Emulator]
- [Handling Signals With Trap]

[antibody]: https://github.com/getantibody/antibody
[antidote]: https://getantidote.github.io/
[antigen]: https://github.com/zsh-users/antigen
[fzf]: https://github.com/junegunn/fzf
[ohmyzsh]: https://github.com/ohmyzsh/ohmyzsh
[zcomet]: https://github.com/agkozak/zcomet
[zplug]: https://github.com/zplug/zplug
[zsh-autosuggestions]: https://github.com/zsh-users/zsh-autosuggestions
[zsh-completions]: https://github.com/zsh-users/zsh-completions
[zsh-history-substring-search]: https://github.com/zsh-users/zsh-history-substring-search
[zsh-syntax-highlighting]: https://github.com/zsh-users/zsh-syntax-highlighting

[awesome zsh plugins]: https://github.com/unixorn/awesome-zsh-plugins
[completion config example]: https://github.com/ThiefMaster/zsh-config/blob/master/zshrc.d/completion.zsh
[fix key settings (home/end/insert/delete) in .zshrc when running zsh in terminator terminal emulator]: https://stackoverflow.com/questions/8638012/fix-key-settings-home-end-insert-delete-in-zshrc-when-running-zsh-in-terminat#8645267
[gentoo wiki]: https://wiki.gentoo.org/wiki/Zsh
[handling signals with trap]: https://stackoverflow.com/questions/59911669/proper-way-to-use-a-trap-to-exit-a-shell-script-in-zsh#59925138
[how can i convert an array into a comma separated string?]: https://stackoverflow.com/questions/53839253/how-can-i-convert-an-array-into-a-comma-separated-string
[how to list all variables names and their current values?]: https://askubuntu.com/questions/275965/how-to-list-all-variables-names-and-their-current-values#275972
[pattern matching in a conditional expression]: https://unix.stackexchange.com/questions/553607/pattern-matching-in-a-zsh-conditional-expression
[remove duplicates in zsh path]: https://til.hashrocket.com/posts/7evpdebn7g-remove-duplicates-in-zsh-path
[substitutions]: http://zsh.sourceforge.net/Guide/zshguide05.html
[the z shell manual]: http://zsh.sourceforge.net/Doc/Release/
[what should/shouldn't go in .zshenv, .zshrc, .zlogin, .zprofile, .zlogout?]: https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout#487889
[zsh compinit: insecure directories and files, run compaudit for list]: https://github.com/zsh-users/zsh-completions/issues/433#issuecomment-619321054
[zsh delete keybinding]: https://superuser.com/questions/983016/zsh-delete-keybinding#983018
