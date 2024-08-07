# FISH

The friendly interactive shell.

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Prompt](#prompt)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Install the shell.
apt install 'fish'
brew install 'fish'
zypper install 'fish'

# Start `fish` sessions.
fish
fish -Pil

# Set variables.
set 'MyVAR' 'someValue'
set -x 'MyExportedVAR' 'someValue'

# Unset variables.
set -e 'MyVAR'

# Change one's default shell to `fish`.
chsh -s (which fish)      # from `fish`
chsh -s "$(which fish)"   # from `{ba,z}sh`

# Open the web-based configuration interface.
fish_config
fish_config browse

# Process substitution.
# What in BASH or ZSH would be `<(echo …)`.
diff -y -W 200 \
  (aws … --output 'json' | psub) \
  (aws … --output 'json' | psub)

# Math.
math 2 '+' 6
time pulumi pre --parallel (math 2 '*' (nproc))

# Array manipulation.
echo (seq 10)[-1..1]  # -> 10 9 8 7 6 5 4 3 2 1
set array "$array appended_element"

# Define CLI options.
# Use all lines.
set -l opts
set opts $opts (fish_opt -s 'c' -l 'command' --required-val)
set opts $opts (fish_opt -s 'p' -l 'path' --multiple-vals)
argparse $opts -- $argv
or return
echo $_flag_command
echo $_flag_path
echo $argv

# Switch.
switch $animal
  case cat
    echo evil
  case wolf dog human moose dolphin whale
    echo mammal
  case duck goose albatross
    echo bird
  case shark trout stingray
    echo fish
  case '*'
    echo I have no idea what a $animal is
end
```

For functions defined in files in `~/.config/fish/functions/` to be automatically available, the files need to:

- Host **a single** function each.
- Be named as the function they host.

## Configuration

Shell configuration file: `~/.config/fish/config.fish`.<br/>
`.fish` scripts in `~/.config/fish/conf.d/` are automatically executed **before** `config.fish`.

Configuration files are read at startup of every session, whether the shell is interactive and/or login.<br/>
Use `status --is-interactive` and `status --is-login` to discriminate between interactive/login shells, respectively:

```sh
if status --is-login
  fish_add_path ~/bin
end
```

`fish` offers a web-based configuration interface. Open it executing `fish_config`.

## Prompt

See [Starship] or [Tide].

## Further readings

- [Website]
- [`bash`][bash]
- [`zsh`][zsh]
- [Fish shell cheatsheet]

Prompts:

- [Starship] (prompt)
- [Tide] (prompt)

Frameworks:

- [Oh My Fish][oh-my-fish]

## Sources

All the references in the [further readings] section, plus the following:

- [Documentation]
- [Github]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[bash]: bash.md
[oh-my-fish]: https://github.com/oh-my-fish/oh-my-fish
[starship]: starship.md
[zsh]: zsh.md

<!-- Files -->
<!-- Upstream -->
[documentation]: https://fishshell.com/docs/current/
[github]: https://github.com/fish-shell/fish-shell
[website]: https://fishshell.com/

<!-- Others -->
[fish shell cheatsheet]: https://devhints.io/fish-shell
[tide]: https://github.com/IlanCosman/tide
