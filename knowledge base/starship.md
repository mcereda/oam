# Starship

Fast and customizable prompt for most shells.

1. [TL;DR](#tldr)
1. [Configuration](#configuration)
1. [Further readings](#further-readings)
1. [Sources](#sources)

## TL;DR

```sh
# Installation.
brew install 'starship'
zypper in 'starship'

# Start when the shell starts.
eval "$(starship init bash)" | tee -a ~'/.bashrc'
echo 'starship init fish | source' | tee -a ~'/.config/fish/config.fish'
eval "$(starship init zsh)" | tee -a ~'/.zshrc'

# Initialize starship configuration.
mkdir -p ~'/.config' && touch ~'/.config/starship.toml'

# List available presets (prompt styles).
starship preset -l
```

## Configuration

```sh
# ~/.config/starship.toml

# Get editor completions based on the config schema.
"$schema" = 'https://starship.rs/config-schema.json'

# Replace the default '❯' symbol in the prompt with '$'.
# The '$' character needs to be escaped.
[character]
success_symbol = '[\$](bold green)'
```

## Further readings

- [Website]
- [Nerd fonts]

## Sources

All the references in the [further readings] section, plus the following:

- [Github]

<!--
  References
  -->

<!-- In-article sections -->
[further readings]: #further-readings

<!-- Knowledge base -->
[bash]: bash.md
[fish]: fish.md
[nerd fonts]: nerd%20fonts.md
[zsh]: zsh.md

<!-- Files -->
<!-- Upstream -->
[github]: https://github.com/starship/starship
[website]: https://starship.rs/

<!-- Others -->
