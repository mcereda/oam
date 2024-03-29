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
```

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
